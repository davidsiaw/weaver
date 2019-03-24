require 'weaver/element_types/dynamic_table_cell'
module Weaver
  # Tables that dynamically load data
  class DynamicTable
    def initialize(page, anchors, url, options = {}, &block)
      @page = page
      @anchors = anchors
      @url = url
      @options = options
      @columns = nil
      @query_object = nil

      instance_eval(&block) if block

      @options[:id] ||= @page.create_anchor 'dyn_table'
      @table_name = @options[:id]
      @head_name = "#{@table_name}_head"
      @body_name = "#{@table_name}_body"
    end

    def column(name, options = {}, &block)
      @columns = [] if @columns.nil?

      title = options[:title] || name
      format = nil
      transform = nil

      if options[:icon]
        elem = Elements.new(@page, @anchors)
        elem.instance_eval do
          icon options[:icon]
          text " #{title}"
        end
        title = elem.generate
      end

      if block
        elem = DynamicTableCell.new(@page, @anchors)
        elem.instance_eval(&block)
        format = elem.generate
        if elem.transform_script
          func_name = @page.create_anchor 'transform'
          @page.write_script_once <<-SCRIPT
document.transform_#{func_name} = function (input)
{
#{elem.transform_script}
}
          SCRIPT

          transform = func_name
         end
      end

      @columns << { name: name, title: title, format: format, transform: transform }
    end

    def generate_table
      table_name = @table_name
      head_name = @head_name
      body_name = @body_name
      options = @options

      columns = @columns || [{ title: 'Key' }, { title: 'Value' }]

      elem = Elements.new(@page, @anchors)
      elem.instance_eval do
        table options do
          thead id: head_name do
            columns.each do |column, _|
              if column.is_a? Hash
                th column[:title].to_s
              else
                th column.to_s
              end
            end
          end

          tbody id: body_name do
          end
        end
      end

      elem.generate
    end

    def query(&block)
      @query_object = JavaScriptObject.new(&block)
    end

    def generate_script
      query_object_declaration = '{}'
      query_string = ''

      if @query_object
        query_object_declaration = @query_object.generate
        query_string = '+ "?" + $.param(query_object)'
      end

      member_expr = ''
      member_expr = ".#{@options[:member]}" if @options[:member]

      <<-DATATABLE_SCRIPT

	function refresh_table_#{@table_name}()
	{
		var query_object = #{query_object_declaration};

		$.get( "#{@url}" #{query_string}, function( returned_data )
		{
			var data = returned_data#{member_expr};
			var data_object = {};
			if (data !== null && typeof data === 'object')
			{
				data_object = data;
			}
			else
			{
				data_object = JSON.parse(data);
			}

			var head = $("##{@head_name}")
			var body = $("##{@body_name}")

			if($.isPlainObject(data_object))
			{
				for (var key in data_object)
				{
					var row = $('<tr>');
					row.append($('<td>').text(key));
					row.append($('<td>').text(data_object[key]));
					body.append(row);
				}
			}

			if ($.isArray(data_object))
			{

				var columnData = JSON.parse(#{@columns.to_json.inspect});
				var columns = {};
				var columnTitles = [];
				head.empty();
				if (#{@columns.nil?})
				{
					// Set up columns
					for (var index in data_object)
					{
						for (var key in data_object[index])
						{
							columns[key] = Object.keys(columns).length;
						}
					}
					for (var key in columns)
					{
						columnTitles.push(key);
					}
				}
				else
				{
					for (var key in columnData)
					{
						columns[columnData[key]["name"]] = Object.keys(columns).length;
						columnTitles.push(columnData[key]["title"]);
					}
				}

				var row = $('<tr>');
				for (var key in columnTitles)
				{
					var columnTitle = $('<th>').html(columnTitles[key]);
					row.append(columnTitle);
				}
				head.append(row);

				for (var index in data_object)
				{
					var row = $('<tr>');
					for (var columnIndex = 0; columnIndex < Object.keys(columns).length; columnIndex++) {
						var cell_data = data_object[index][ Object.keys(columns)[columnIndex] ];

						if (columnData && columnData[columnIndex]["format"])
						{
							var format = columnData[columnIndex]["format"];
							var matches = format.match(/###.+?###/g)

							var result = format;
							for (var matchIndex in matches)
							{
								var member_name = matches[matchIndex].match(/[^#]+/)[0];
								result = result.replaceAll(matches[matchIndex], data_object[index][member_name]);
							}

							if (columnData && columnData[columnIndex]["transform"])
							{
								result = document["transform_" + columnData[columnIndex]["transform"]](result);
							}
							row.append($('<td>').html( result ).data("object", data_object[index]) );
						}
						else
						{
							if (columnData && columnData[columnIndex]["transform"])
							{
								cell_data = document["transform_" + columnData[columnIndex]["transform"]](cell_data);
							}
							row.append($('<td>').text( cell_data ).data("object", data_object[index]) );
						}
					}
					body.append(row);
				}
			}

		});
	}

	refresh_table_#{@table_name}();

      DATATABLE_SCRIPT
    end
  end

  # Add tables to elements
  class Elements
    def table(options = {}, &block)
      table_name = options[:id] || @page.create_anchor('table')
      table_style = ''

      table_style = options[:style] unless options[:style].nil?

      classname = 'table'

      classname += ' table-bordered' if options[:bordered]
      classname += ' table-hover' if options[:hover]
      classname += ' table-striped' if options[:striped]

      table_options = {
        class: classname,
        id: table_name,
        style: table_style
      }

      if options[:system] == :data_table
        @page.request_js 'js/plugins/dataTables/jquery.dataTables.js'
        @page.request_js 'js/plugins/dataTables/dataTables.bootstrap.js'
        @page.request_js 'js/plugins/dataTables/dataTables.responsive.js'
        @page.request_js 'js/plugins/dataTables/dataTables.tableTools.min.js'

        @page.request_css 'css/plugins/dataTables/dataTables.bootstrap.css'
        @page.request_css 'css/plugins/dataTables/dataTables.responsive.css'
        @page.request_css 'css/plugins/dataTables/dataTables.tableTools.min.css'

        @page.scripts << <<-DATATABLE_SCRIPT
		$('##{table_name}').DataTable();
        DATATABLE_SCRIPT
      end

      if options[:system] == :foo_table
        table_options[:"data-filtering"] = true
        table_options[:"data-sorting"] = true
        table_options[:"data-paging"] = true
        table_options[:"data-show-toggle"] = true
        table_options[:"data-toggle-column"] = 'last'

        table_options[:"data-paging-size"] = (options[:max_items_per_page] || 8).to_i.to_s
        table_options[:class] = table_options[:class] + ' toggle-arrow-tiny'

        @page.request_js 'js/plugins/footable/footable.all.min.js'

        @page.request_css 'css/plugins/footable/footable.core.css'

        @page.scripts << <<-DATATABLE_SCRIPT
		$('##{table_name}').footable({
			paging: {
				size: #{(options[:max_items_per_page] || 8).to_i}
			}
		});
		$('##{table_name}').append(this.html).trigger('footable_redraw');



        DATATABLE_SCRIPT

        @page.onload_scripts << <<-SCRIPT
        				SCRIPT
      end

      method_missing(:table, table_options, &block)
      ul class: 'pagination'
    end

    def table_from_source(url, options = {}, &block)
      dyn_table = DynamicTable.new(@page, @anchors, url, options, &block)

      text dyn_table.generate_table

      @page.scripts << dyn_table.generate_script
    end

    def table_from_hashes(hashes, options = {})
      keys = {}
      hashes.each do |hash|
        hash.each do |key, _value|
          keys[key] = ''
        end
      end

      table options do
        thead do
          keys.each do |key, _|
            th key.to_s
          end
        end

        tbody do
          hashes.each do |hash|
            tr do
              keys.each do |key, _|
                td (hash[key]).to_s || '&nbsp;'
              end
            end
          end
        end
      end
    end
  end
end
