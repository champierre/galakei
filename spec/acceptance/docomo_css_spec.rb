# encoding: UTF-8
require File.expand_path(File.dirname(__FILE__) + '/acceptance_helper')
require 'fakeweb'

class DocomoCssController < ApplicationController
  def simple
    html = <<-EOD
      <% content_for(:head, stylesheet_link_tag("docomo_css/simple.css")) %>
      <span>color</span>
    EOD
    render :inline => html, :layout => true
  end

  def external
    html = <<-EOD
      <% content_for(:head, stylesheet_link_tag("http://www.galakei.com/external.css")) %>
      <span>color</span>
    EOD
    render :inline => html, :layout => true
  end

  def div
    html = <<-EOD
      <% content_for(:head, stylesheet_link_tag("http://www.galakei.com/external.css")) %>
      <div>test</div>
    EOD
    render :inline => html, :layout => true
  end


  def japanese
    html = <<-EOD
      <% content_for(:head, stylesheet_link_tag("docomo_css/simple.css")) %>
      ほげ
    EOD
    render :inline => html, :layout => true
  end
end

feature 'inlining of css' do
  scenario 'requesting simple page for docomo', :driver => :docomo do
    parser = CssParser::Parser.new
    parser.add_block!('span { color: red}') 
    Galakei::DocomoCss::InlineStylesheet.stub(:parser) { parser }
    visit '/docomo_css/simple'
    find("span")["style"].should == "color: red;"
    page.should_not have_xpath("//link")
  end

  scenario 'requesting external page for docomo', :driver => :docomo do
    FakeWeb.register_uri(:get, 'http://www.galakei.com/external.css', :body => "span { color: red }")
    visit '/docomo_css/external'
    find("span")["style"].should == "color: red;"
    page.should_not have_xpath("//link")
  end

  %w[au softbank docomo_2_0].each do |carrier|
    scenario "requesting simple page for #{carrier}", :driver => carrier.to_sym do
      visit '/docomo_css/simple'
      find("span")["style"].should be_nil
    end
  end

  scenario 'response contains non-ascii', :driver => :docomo do
    visit '/docomo_css/japanese'
    page.body.should include("ほげ")
  end

  %w[#000000 black].each do |s|
    scenario "requesting page with #{s} border", :driver => :docomo do
      FakeWeb.register_uri(:get, 'http://www.galakei.com/external.css', :body => "div { border-top: 1px solid #{s} }")
      visit '/docomo_css/div'
      div = find('img')
      div["width"].should == "100%"
      div["height"].should == "1"
      visit div['src']
      page.body.should include("GIF89a")
    end
  end
end
