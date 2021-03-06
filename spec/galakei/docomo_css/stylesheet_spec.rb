require 'spec_helper'
require 'nokogiri'

describe Galakei::DocomoCss::Stylesheet do
  context "simple stylesheet" do
    before do
      parser = CssParser::Parser.new
      parser.add_block!(<<-EOD)
        span {
          color: red;
        }
      EOD
      @stylesheet = described_class.new(parser)
    end
    it "should apply style to matching element" do
      doc = Nokogiri::HTML.fragment("<span>foo</span>")
      @stylesheet.apply(doc)
      doc.to_s.should == %q{<span style="color: red;">foo</span>}
    end
    it "should not apply style to non-matching element" do
      doc = Nokogiri::HTML.fragment("<p>foo</p>")
      @stylesheet.apply(doc)
      doc.to_s.should == %q{<p>foo</p>}
    end
  end
  
  context "stylesheet with multiple styles" do
    before do
      parser = CssParser::Parser.new
      parser.add_block!(<<-EOD)
        div {
          background-color: red;
        }
        
        .alC {
          text-align: center
        }
      EOD
      @stylesheet = described_class.new(parser)
    end

    it "should apply style to element that matches one style" do
      doc = Nokogiri::HTML.fragment("<div class='alC'>foo</span>")
      @stylesheet.apply(doc)
      doc.to_s.should == %q{<div class="alC" style="background-color: red;text-align: center;">foo</div>}
    end
  end

  context "stylesheet with pseudo style" do
    before do
      parser = CssParser::Parser.new
      parser.add_block!(<<-EOD)
        a:link      { color: red; }
        a:focus     { color: green; }
        a:visited   { color: blue; }
      EOD
      @stylesheet = described_class.new(parser)
    end

    it "should add to head" do
      doc = Nokogiri::HTML(<<-EOD)
        <html>
          <head></head>
          <body><a href="/">foo</a></body>
        </html>
      EOD
      @stylesheet.apply(doc)
      doc.at("//a").to_s.should == %q{<a href="/">foo</a>}
      expected = <<-EOD
<style type="text/css">
<![CDATA[
a:link { color: red; }
a:focus { color: green; }
a:visited { color: blue; }
]]>
</style>
EOD
      doc.at("/html/head/style").to_s.strip.should == expected.strip
    end
  end

  ((1..6).map {|i| "h#{i}"} + %w[p td]).each do |tag|
    context "style applied to #{tag}" do
      before do
        parser = CssParser::Parser.new
        parser.add_block!(<<-EOD)
          #{tag}.color { color: red; }
          #{tag}.fontsize { font-size: x-small; }
          #{tag}.backgroundcolor { background-color: blue; }
          .classonly { line-height: 1px; }
        EOD
        @stylesheet = described_class.new(parser)
      end

      it "should wrap children in span for color" do
        doc = Nokogiri::HTML("<#{tag} class='color'>foo</#{tag}>")
        @stylesheet.apply(doc)
        doc.at("//#{tag}").to_s.should == %Q{<#{tag} class="color"><span style="color: red;">foo</span></#{tag}>}
      end

      it "should wrap children in span for font-size" do
        doc = Nokogiri::HTML("<#{tag} class='fontsize'>foo</#{tag}>")
        @stylesheet.apply(doc)
        doc.at("//#{tag}").to_s.should == %Q{<#{tag} class="fontsize"><span style="font-size: x-small;">foo</span></#{tag}>}
      end

      it "should wrap multiple children in single span" do
        doc = Nokogiri::HTML("<#{tag} class='fontsize'>foo<br />bar</#{tag}>")
        @stylesheet.apply(doc)
        doc.at("//#{tag}").to_s.should == %Q{<#{tag} class="fontsize"><span style="font-size: x-small;">foo<br>bar</span></#{tag}>}
      end

      it "should applied css of tag omitted" do
        doc = Nokogiri::HTML("<#{tag} class='classonly'>foo</#{tag}>")
        @stylesheet.apply(doc)
        doc.at("//#{tag}").to_s.should == %Q{<#{tag} class="classonly" style="line-height: 1px;">foo</#{tag}>}
      end
    end
  end


  ((1..6).map {|i| "h#{i}"} + %w[p]).each do |tag|
    context "style applied to #{tag}" do
      before do
        parser = CssParser::Parser.new
        parser.add_block!(<<-EOD)
          #{tag}.backgroundcolor { background-color: blue; }
        EOD
        @stylesheet = described_class.new(parser)
      end
      it "should wrap element in div for background-color" do
        doc = Nokogiri::HTML("<#{tag} class='backgroundcolor'>foo</#{tag}>")
        @stylesheet.apply(doc)
        doc.at("//div").to_s.should == %Q{<div style="background-color: blue;"><#{tag} class="backgroundcolor">foo</#{tag}></div>}
      end
    end
  end

  context "style applied to td" do
    before do
      parser = CssParser::Parser.new
      parser.add_block!(<<-EOD)
        td { background-color: blue; }
      EOD
      @stylesheet = described_class.new(parser)
    end
    it "should wrap element in div for background-color" do
      doc = Nokogiri::HTML("<td>foo</td>")
      @stylesheet.apply(doc)
      doc.at("//td").to_s.should == %Q{<td style="background-color: blue;">foo</td>}
    end
  end


  context "style applied to child of h1" do
    before do
      parser = CssParser::Parser.new
      parser.add_block!(<<-EOD)
        h1 span { color: red; }
      EOD
      @stylesheet = described_class.new(parser)
    end

    it "should not apply style to single h1" do
      doc = Nokogiri::HTML("<h1>foo</h1>")
      @stylesheet.apply(doc)
      doc.at("//h1").to_s.should == %q{<h1>foo</h1>}
    end

    it "should apply style to neseted element" do
      doc = Nokogiri::HTML("<h1><span>foo</span></h1>")
      @stylesheet.apply(doc)
      doc.at("//h1").to_s.should == %q{<h1><span style="color: red;">foo</span></h1>}
    end
  end

  shared_examples_for 'border' do
    it 'applied border' do
      elm = subject
      elm.previous_sibling.to_s.should == @img
      elm.next_sibling.to_s.should == @img
    end
  end

  shared_examples_for 'not border' do
    it "don't applied border" do
      elm = subject
      elm.previous_sibling.to_s.should_not == @img
      elm.next_sibling.to_s.should_not == @img
    end
  end

  shared_examples_for 'border bottom' do
    it 'applied border bottom' do
      elm = subject
      elm.previous_sibling.to_s.should_not == @img
      elm.next_sibling.to_s.should == @img
    end
  end

  shared_examples_for 'border top' do
    it 'applied border top' do
      elm = subject
      elm.previous_sibling.to_s.should == @img
      elm.next_sibling.to_s.should_not == @img
    end
  end

  context 'border css applied to div' do
    let(:body) { "<div>test</div>" }
    before do
      parser = CssParser::Parser.new
      parser.add_block!(css)
      @stylesheet = described_class.new(parser)
      @doc = Nokogiri::HTML(body)
      @stylesheet.apply(@doc)
      @img = %q[<img src="/galakei/spacer/000000" width="100%" height="1">]
    end
    subject { @doc.at('//div') }

    context 'border' do
      let(:css) { "div { border: 1px solid #000000; } "}
      it_should_behave_like 'border'
    end

    context 'border-top' do
      let(:css) { "div { border-top: 1px solid #000000; } "}
      it_should_behave_like 'border top'
    end

    context 'border-bottom' do
      let(:css) { "div { border-bottom: 1px solid #000000; } "}
      it_should_behave_like 'border bottom'
    end

    context 'bordre with class' do
      let(:css) { ".border { border: 1px solid #000000; }" }
      let(:body) { "<div class='border'>test</div>" }
      it_should_behave_like 'border'
    end

    context 'border-bottom with height' do
      let(:css) { "div { border-bottom: 5px solid #000000; } "}
      it 'applied border bottom' do
        subject.next_sibling.to_s.should == %q[<img src="/galakei/spacer/000000" width="100%" height="5">]
      end
    end
  end

  context 'border css applied to h(n)' do
    before do
      parser = CssParser::Parser.new
      parser.add_block!(css)
      @stylesheet = described_class.new(parser)
      @doc = Nokogiri::HTML("<h1>test</h1>")
      @stylesheet.apply(@doc)
      @img = %q[<img src="/galakei/spacer/000000" width="100%" height="1">]
    end
    subject { @doc.at("//h1") }

    context 'border' do
      let(:css) { "h1 { border: 1px solid #000000; } "}
      it_should_behave_like 'border'
    end

    context 'border-top' do
      let(:css) { "h1 { border-top: 1px solid #000000; } "}
      it_should_behave_like 'border top'
    end

    context 'border-bottom' do
      let(:css) { "h1 { border-bottom: 1px solid #000000; } "}
      it_should_behave_like 'border bottom'
    end

    context 'border bottom with !important' do
      let(:css) { "h1 { border-bottom: 1px solid #96ca41 !important; } "}
      it 'applied border bottom' do
        subject.next_sibling.to_s.should == %q[<img src="/galakei/spacer/96ca41" width="100%" height="1">]
      end
    end
  end

  context 'border css applied to p' do
    before do
      parser = CssParser::Parser.new
      parser.add_block!(css)
      @stylesheet = described_class.new(parser)
      @doc = Nokogiri::HTML("<p>test</p>")
      @stylesheet.apply(@doc)
      @img = %q[<img src="/galakei/spacer/000000" width="100%" height="1">]
    end
    subject { @doc.at("//p") }

    context 'border' do
      let(:css) { "p { border: 1px solid #000000; } "}
      it_should_behave_like 'not border'
    end
  end
end
