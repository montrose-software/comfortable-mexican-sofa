require File.dirname(__FILE__) + '/../test_helper'

class CmsPageTest < ActiveSupport::TestCase
  
  def test_fixtures_validity
    CmsPage.all.each do |page|
      assert page.valid?, page.errors.full_messages
    end
  end
  
  def test_validations
    page = CmsPage.new
    page.save
    assert page.invalid?
    assert_has_errors_on page, [:cms_layout, :slug, :label]
  end
  
  def test_validation_of_parent_relationship
    page = cms_pages(:default)
    assert !page.parent
    page.parent = page
    assert page.invalid?
    assert_has_errors_on page, :parent_id
    page.parent = cms_pages(:child)
    assert page.invalid?
    assert_has_errors_on page, :parent_id
  end
  
  def test_initialization_of_full_path
    page = CmsPage.new(new_params)
    assert page.invalid?
    assert_has_errors_on page, :full_path
    
    page = CmsPage.new(new_params(:parent => cms_pages(:default)))
    assert page.valid?
    assert_equal '/test-page', page.full_path
    
    page = CmsPage.new(new_params(:parent => cms_pages(:child)))
    assert page.valid?
    assert_equal '/child-page/test-page', page.full_path
    
    CmsPage.destroy_all
    page = CmsPage.new(new_params)
    assert page.valid?
    assert_equal '/', page.full_path
  end
  
  def test_sync_child_pages
    page = cms_pages(:child)
    page_1 = CmsPage.create!(new_params(:parent => page, :slug => 'test-page-1'))
    page_2 = CmsPage.create!(new_params(:parent => page, :slug => 'test-page-2'))
    page_3 = CmsPage.create!(new_params(:parent => page_2, :slug => 'test-page-3'))
    page_4 = CmsPage.create!(new_params(:parent => page_1, :slug => 'test-page-4'))
    assert_equal '/child-page/test-page-1', page_1.full_path
    assert_equal '/child-page/test-page-2', page_2.full_path
    assert_equal '/child-page/test-page-2/test-page-3', page_3.full_path
    assert_equal '/child-page/test-page-1/test-page-4', page_4.full_path
    
    page.update_attributes!(:slug => 'updated-page')
    assert_equal '/updated-page', page.full_path
    page_1.reload; page_2.reload; page_3.reload; page_4.reload
    assert_equal '/updated-page/test-page-1', page_1.full_path
    assert_equal '/updated-page/test-page-2', page_2.full_path
    assert_equal '/updated-page/test-page-2/test-page-3', page_3.full_path
    assert_equal '/updated-page/test-page-1/test-page-4', page_4.full_path
    
    page_2.update_attributes!(:parent => page_1)
    page_1.reload; page_2.reload; page_3.reload; page_4.reload
    assert_equal '/updated-page/test-page-1', page_1.full_path
    assert_equal '/updated-page/test-page-1/test-page-2', page_2.full_path
    assert_equal '/updated-page/test-page-1/test-page-2/test-page-3', page_3.full_path
    assert_equal '/updated-page/test-page-1/test-page-4', page_4.full_path
  end
  
  def test_initialize_tags
    page = CmsPage.new
    page.initialize_tags
    assert_equal 0, page.cms_blocks.size
    
    page.cms_layout = cms_layouts(:default)
    page.initialize_tags
    assert_equal 3, page.cms_blocks.size
    
    page.cms_layout_id = '999999'
    page.initialize_tags
    assert_equal 0, page.cms_blocks.size
    
    page.cms_layout_id = cms_layouts(:default).id
    page.initialize_tags
    assert_equal 3, page.cms_blocks.size
  end
  
  def test_render_content_for_saved_page
    page = cms_pages(:default)
    assert_equal [
      'default_page_text_content',
      'default_page_string_content',
      '1'
    ].join("\n"), page.render_content
  end
  
  def test_render_content_for_initialized_page
    page = CmsPage.new(new_params)
    assert page.render_content.blank?
    
    assert_equal 3, page.cms_blocks.size
    page.cms_blocks.each_with_index do |block, i|
      block.content = "content_#{i}"
    end
    assert_equal [
      'content_0',
      'content_1',
      '0'
    ].join("\n"), page.render_content
  end
  
  def test_children_count_updating
    page_1 = cms_pages(:default)
    page_2 = cms_pages(:child)
    assert_equal 1, page_1.children_count
    assert_equal 0, page_2.children_count
    
    page_3 = CmsPage.create!(new_params(:parent => page_2))
    page_1.reload; page_2.reload
    assert_equal 1, page_1.children_count
    assert_equal 1, page_2.children_count
    assert_equal 0, page_3.children_count
    
    page_3.update_attributes!(:parent => page_1)
    page_1.reload; page_2.reload
    assert_equal 2, page_1.children_count
    assert_equal 0, page_2.children_count
    
    page_3.destroy
    page_1.reload; page_2.reload
    assert_equal 1, page_1.children_count
    assert_equal 0, page_2.children_count
  end
  
  def test_cascading_destroy
    assert_difference 'CmsPage.count', -2 do
      cms_pages(:default).destroy
    end
  end
  
  def test_options_for_select
    assert_equal ['Default Page', '. . Child Page'], CmsPage.options_for_select.collect{|t| t.first }
    assert_equal ['Default Page'], CmsPage.options_for_select(cms_pages(:child)).collect{|t| t.first }
    assert_equal [], CmsPage.options_for_select(cms_pages(:default))
    
    page = CmsPage.new(new_params(:parent => cms_pages(:default)))
    assert_equal ['Default Page', '. . Child Page'], CmsPage.options_for_select(page).collect{|t| t.first }
  end
  
protected
  
  def new_params(options = {})
    {
      :label      => 'Test Page',
      :slug       => 'test-page',
      :cms_layout => cms_layouts(:default)
    }.merge(options)
  end
end