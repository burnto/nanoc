# encoding: utf-8

require 'test/helper'

class Nanoc3::DataSources::FilesystemVeboseTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  def test_items
    # Create data source
    data_source = Nanoc3::DataSources::FilesystemVerbose.new(nil, nil, nil, nil)

    # Create foo item
    FileUtils.mkdir_p('content/foo')
    File.open('content/foo/foo.yaml', 'w') do |io|
      io.write("---\n")
      io.write("title: Foo\n")
    end
    File.open('content/foo/foo.html', 'w') do |io|
      io.write('Lorem ipsum dolor sit amet...')
    end

    # Create bar item
    FileUtils.mkdir_p('content/bar')
    File.open('content/bar/bar.yaml', 'w') do |io|
      io.write("---\n")
      io.write("title: Bar\n")
    end
    File.open('content/bar/bar.xml', 'w') do |io|
      io.write("Lorem ipsum dolor sit amet...")
    end

    # Load items
    items = data_source.items

    # Check items
    assert_equal(2, items.size)
    assert(items.any? { |a|
      a[:title]            == 'Foo' &&
      a[:extension]        == 'html' &&
      a[:content_filename] == 'content/foo/foo.html' &&
      a[:meta_filename]    == 'content/foo/foo.yaml'
    })
    assert(items.any? { |a|
      a[:title]            == 'Bar' &&
      a[:extension]        == 'xml' &&
      a[:content_filename] == 'content/bar/bar.xml' &&
      a[:meta_filename]    == 'content/bar/bar.yaml'
    })
  end

  def test_items_with_period_in_name
    data_source = Nanoc3::DataSources::FilesystemVerbose.new(nil, nil, nil, { :allow_periods_in_identifiers => true })

    # Create foo.css
    FileUtils.mkdir_p('content/foo')
    File.open('content/foo/foo.yaml', 'w') do |io|
      io.write(YAML.dump({ 'title' => 'Foo' }))
    end
    File.open('content/foo/foo.css', 'w') do |io|
      io.write('body.foo {}')
    end
    
    # Create foo.bar.css
    FileUtils.mkdir_p('content/foo.bar')
    File.open('content/foo.bar/foo.bar.yaml', 'w') do |io|
      io.write(YAML.dump({ 'title' => 'Foo Bar' }))
    end
    File.open('content/foo.bar/foo.bar.css', 'w') do |io|
      io.write('body.foobar {}')
    end
    
    # Load
    items = data_source.items
    
    # Check
    assert_equal 2, items.size
    assert_equal '/foo/',                        items[0].identifier
    assert_equal 'Foo',                          items[0][:title]
    assert_equal 'content/foo/foo.css',          items[0][:content_filename]
    assert_equal 'content/foo/foo.yaml',         items[0][:meta_filename]
    assert_equal '/foo.bar/',                    items[1].identifier
    assert_equal 'Foo Bar',                      items[1][:title]
    assert_equal 'content/foo.bar/foo.bar.css',  items[1][:content_filename]
    assert_equal 'content/foo.bar/foo.bar.yaml', items[1][:meta_filename]
  end

  def test_items_with_optional_meta_file
    # Create data source
    data_source = Nanoc3::DataSources::FilesystemVerbose.new(nil, nil, nil, nil)

    # Create foo item
    FileUtils.mkdir_p('content/foo')
    File.open('content/foo/foo.html', 'w') do |io|
      io.write('Lorem ipsum dolor sit amet...')
    end

    # Create bar item
    FileUtils.mkdir_p('content/bar')
    File.open('content/bar/bar.yaml', 'w') do |io|
      io.write("---\n")
      io.write("title: Bar\n")
    end

    # Load items
    items = data_source.items

    # Check items
    assert_equal(2, items.size)
    assert(items.any? { |a|
      a[:title]            == nil &&
      a[:extension]        == 'html' &&
      a[:content_filename] == 'content/foo/foo.html' &&
      a[:meta_filename]    == nil
    })
    assert(items.any? { |a|
      a[:title]            == 'Bar' &&
      a[:extension]        == nil &&
      a[:content_filename] == nil &&
      a[:meta_filename]    == 'content/bar/bar.yaml'
    })
  end

  def test_layouts
    # Create data source
    data_source = Nanoc3::DataSources::FilesystemVerbose.new(nil, nil, nil, nil)

    # Create layout
    FileUtils.mkdir_p('layouts/foo')
    File.open('layouts/foo/foo.yaml', 'w') do |io|
      io.write("---\n")
      io.write("filter: erb\n")
    end
    File.open('layouts/foo/foo.rhtml', 'w') do |io|
      io.write('Lorem ipsum dolor sit amet...')
    end

    # Load layouts
    layouts = data_source.layouts

    # Check layouts
    assert_equal(1,                       layouts.size)
    assert_equal('erb',                   layouts[0][:filter])
    assert_equal('rhtml',                 layouts[0][:extension])
    assert_equal('layouts/foo/foo.rhtml', layouts[0][:content_filename])
    assert_equal('layouts/foo/foo.yaml',  layouts[0][:meta_filename])
  end

  def test_layouts_with_period_in_name_disallowing_periods_in_identifiers
    data_source = Nanoc3::DataSources::FilesystemVerbose.new(nil, nil, nil, nil)

    # Create foo.html
    FileUtils.mkdir_p('layouts/foo')
    File.open('layouts/foo/foo.yaml', 'w') do |io|
      io.write(YAML.dump({ 'dog' => 'woof' }))
    end
    File.open('layouts/foo/foo.html', 'w') do |io|
      io.write('body.foo {}')
    end
    
    # Create bar.html.erb
    FileUtils.mkdir_p('layouts/bar')
    File.open('layouts/bar/bar.yaml', 'w') do |io|
      io.write(YAML.dump({ 'cat' => 'meow' }))
    end
    File.open('layouts/bar/bar.html.erb', 'w') do |io|
      io.write('body.foobar {}')
    end
    
    # Load
    layouts = data_source.layouts.sort_by { |i| i.identifier }
    
    # Check
    assert_equal 2, layouts.size
    assert_equal '/bar/', layouts[0].identifier
    assert_equal 'meow',  layouts[0][:cat]
    assert_equal '/foo/', layouts[1].identifier
    assert_equal 'woof',  layouts[1][:dog]
  end

  def test_layouts_with_period_in_name_allowing_periods_in_identifiers
    data_source = Nanoc3::DataSources::FilesystemVerbose.new(nil, nil, nil, { :allow_periods_in_identifiers => true })

    # Create foo.html
    FileUtils.mkdir_p('layouts/foo')
    File.open('layouts/foo/foo.yaml', 'w') do |io|
      io.write(YAML.dump({ 'dog' => 'woof' }))
    end
    File.open('layouts/foo/foo.html', 'w') do |io|
      io.write('body.foo {}')
    end
    
    # Create bar.html.erb
    FileUtils.mkdir_p('layouts/bar.xyz')
    File.open('layouts/bar.xyz/bar.xyz.yaml', 'w') do |io|
      io.write(YAML.dump({ 'cat' => 'meow' }))
    end
    File.open('layouts/bar.xyz/bar.xyz.html', 'w') do |io|
      io.write('body.foobar {}')
    end
    
    # Load
    layouts = data_source.layouts.sort_by { |i| i.identifier }
    
    # Check
    assert_equal 2, layouts.size
    assert_equal '/bar.xyz/', layouts[0].identifier
    assert_equal 'meow',      layouts[0][:cat]
    assert_equal '/foo/',     layouts[1].identifier
    assert_equal 'woof',      layouts[1][:dog]
  end

  def test_create_item_at_root
    # Create item
    data_source = Nanoc3::DataSources::FilesystemVerbose.new(nil, nil, nil, nil)
    data_source.create_item('content here', { :foo => 'bar' }, '/')

    # Check file existance
    assert File.directory?('content')
    assert File.file?('content/content.html')
    assert File.file?('content/content.yaml')

    # Check file content
    assert_equal 'content here', File.read('content/content.html')
    assert_match 'foo: bar',     File.read('content/content.yaml')
  end

  def test_create_item_not_at_root
    # Create item
    data_source = Nanoc3::DataSources::FilesystemVerbose.new(nil, nil, nil, nil)
    data_source.create_item('content here', { :foo => 'bar' }, '/moo/')

    # Check file existance
    assert File.directory?('content/moo')
    assert File.file?('content/moo/moo.html')
    assert File.file?('content/moo/moo.yaml')

    # Check file content
    assert_equal 'content here', File.read('content/moo/moo.html')
    assert_match 'foo: bar',     File.read('content/moo/moo.yaml')
  end

  def test_create_layout
    # Create layout
    data_source = Nanoc3::DataSources::FilesystemVerbose.new(nil, nil, nil, nil)
    data_source.create_layout('content here', { :foo => 'bar' }, '/moo/')

    # Check file existance
    assert File.directory?('layouts/moo')
    assert File.file?('layouts/moo/moo.html')
    assert File.file?('layouts/moo/moo.yaml')

    # Check file content
    assert_equal 'content here', File.read('layouts/moo/moo.html')
    assert_match 'foo: bar',     File.read('layouts/moo/moo.yaml')
  end

  def test_compile_huge_site
    # Create data source
    data_source = Nanoc3::DataSources::FilesystemVerbose.new(nil, nil, nil, nil)

    # Create a lot of items
    count = Process.getrlimit(Process::RLIMIT_NOFILE)[0] + 5
    count.times do |i|
      FileUtils.mkdir_p("content/#{i}")
      File.open("content/#{i}/#{i}.html", 'w') { |io| io << "This is item #{i}." }
      File.open("content/#{i}/#{i}.yaml", 'w') { |io| io << "title: Item #{i}"   }
    end

    # Read all items
    data_source.items
  end

end