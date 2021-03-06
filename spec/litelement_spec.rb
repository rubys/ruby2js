gem 'minitest'
require 'minitest/autorun'
require 'ruby2js/filter/lit-element'

describe Ruby2JS::Filter::LitElement do
  
  def to_js(string)
    _(Ruby2JS.convert(string, eslevel: 2021,
      filters: [Ruby2JS::Filter::LitElement]).to_s)
  end
  
  def to_js_esm(string)
    _(Ruby2JS.convert(string, eslevel: 2021,
      filters: [Ruby2JS::Filter::LitElement, Ruby2JS::Filter::ESM]).to_s)
  end

  describe "properties" do
    it "should handle string properties" do
      a = to_js('class C < LitElement; def initialize; @a = "x"; end; end')
      a.must_include 'static get properties() {return {a: {type: String}}}'
      a.must_include 'constructor() {super(); this.a = "x"}'
    end

    it "should handle boolean properties" do
      a = to_js('class C < LitElement; def initialize; @a = true; end; end')
      a.must_include 'static get properties() {return {a: {type: Boolean}}}'
      a.must_include 'constructor() {super(); this.a = true}'
    end

    it "should handle numeric properties" do
      a = to_js('class C < LitElement; def initialize; @a = 0; end; end')
      a.must_include 'static get properties() {return {a: {type: Number}}}'
      a.must_include 'constructor() {super(); this.a = 0}'
    end

    it "should handle array properties" do
      a = to_js('class C < LitElement; def initialize; @a = []; end; end')
      a.must_include 'static get properties() {return {a: {type: Array}}}'
      a.must_include 'constructor() {super(); this.a = []}'
    end

    it "should handle property updates" do
      to_js('class C < LitElement; def clickHandler(); @count += 1; end; end').
        must_include 'clickHandler() {this.count++}}'

      to_js('class C < LitElement; def clickHandler(); @toggle = !@toggle; end; end').
        must_include 'clickHandler() {this.toggle = !this.toggle}}'
    end
  end

  describe "auto HTML and CSS" do
    it "should handle self.styles" do
      to_js('class C < LitElement; def self.styles; %{.red {color: red}}; end; end').
        must_include 'css`.red {color: red}`'
    end

    it "should handle render" do
      to_js('class C < LitElement; def render; %{<p>x</p>}; end; end').
        must_include 'html`<p>x</p>`'
      to_js('class C < LitElement; def render; %{<p>#{x ? "<br/>" : "<hr/>"}</p>}; end; end').
        must_include '${x ? html`<br/>` : html`<hr/>`}'
      to_js('class C < LitElement; def render; %{<ul>#{x.map {|item| "<li>#{item}</li>"}}</ul>}; end; end').
        must_include '${x.map(item => html`<li>${item}</li>`)}'
    end
  end

  describe "no autobind" do
    it "should disable autobind" do
      to_js('class C < LitElement; ' +
        'def render; %{<a @click="#{clickHandler}">link</a>}; end; ' + 
        'def clickHandler(event); console.log(event); end; end').
        must_include 'html`<a @click="${this.clickHandler}">link</a>`'
    end
  end

  describe "modules" do
    it "imports from lit-element" do
      to_js_esm( 'class Foo<LitElement; end' ).
        must_equal 'import { LitElement, css, html } from "lit-element"; ' +
          'class Foo extends LitElement {}'
    end
  end

  describe Ruby2JS::Filter::DEFAULTS do
    it "should include LitElement" do
      _(Ruby2JS::Filter::DEFAULTS).must_include Ruby2JS::Filter::LitElement
    end
  end
end
