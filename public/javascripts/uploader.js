var AwesomeUploaderInstance3;

var uploaded_files = 0, selected_files = 0, uploaded = [];

function showAddMediaWin() {
  AwesomeUploaderInstance3.show();
}

function closeEditMediaWindow() {
  editMediaWindow.hide();
  jQuery('.more_media_preview').html('');
  uploaded = [];
  uploaded_files = 0;
  selected_files = 0;
}

function startUpdate() {
	var canPost = true;
	jQuery('#edit_media_form [required]').each(function (index, e) {
		var element = $(e);
		if (element.val() == "") {
			element.addClass('error_field');
			canPost = false;
		}
	});
	if (canPost) {
		$('.error').hide();
		$('.error_field').removeClass('error_field');
		Ext.get('media-update-process').show();
    document.getElementById('edit_media_form').submit();
	} else {
		jQuery('#edit_media_form #upload-error').html('Fill in highlited fields');
		jQuery('#edit_media_form #upload-error').removeClass('x-hidden');
		jQuery('#edit_media_form #upload-error').show();
	}
}

function updateFailed(successfuly_uploaded, errors) {
	$('#media-update-process').hide();
	successfuly_uploaded = successfuly_uploaded || []
	errors = errors || []
	for (key in successfuly_uploaded) {
		position = successfuly_uploaded[key]['position'];
		jQuery('#uploaded_' + position).remove();
	}
	for (key in errors) {
		position = errors[key]['position'];
		message = errors[key]['message'];
		jQuery('<span class="error">' + message + '</span>').prependTo('#uploaded_' + position);
	}
    Ext.get('media-update-process').hide();
    var uploadErrorContainer = Ext.get('upload-error');
	if (uploadErrorContainer) {
    	uploadErrorContainer.update('There was an error during file upload!');
	    uploadErrorContainer.removeClass('x-hidden');
	}
    return true;
}

function update_locations_media_list_with_uploaded_items(uploaded_files, errors) {
	$('#media-update-process').hide();
  var list = document.getElementById("media-list-table");
  $('#media-list .media-row.empty-row').remove();
  for (var i=0; i < uploaded_files.length; i++){
    var item = list.appendChild(document.createElement("a"));
    item.innerHTML = '<div class="media-actions">\
      <div class="left media-size">' + uploaded_files[i].size + '</div>\
      <div onclick="return deleteMedia(' + uploaded_files[i].id + ');" href="#" class="delete-link left">\
      <div class="left"></div>\
      </div></div>\
      <div class="media-name media-type-' + uploaded_files[i].type + '">\
      <input type="hidden" value="' + uploaded_files[i].id + '" name="location[medium_ids][]" class="selected_medium">\
      <span>' + uploaded_files[i].name + '</span>\
      </div>\
      <div class="clear"></div>';
      item.className = "media-row";
      item.id = "media_row_" + uploaded_files[i].id;
  }
  if (!errors){
  	closeEditMediaWindow();
  }
}

Ext.onReady(function() {
  var statusIconRenderer = function(value){
    if(value.match(/Pending/)){
      return '<img src="/javascripts/extjs/awesome_uploader/hourglass.png" width=16 height=16>';
    } else if(value.match(/Sending/)) {
      return '<img src="/javascripts/extjs/awesome_uploader/loading.gif" width=16 height=16>';
    } else if(value.match(/Error/)) {
      return '<img src="/javascripts/extjs/awesome_uploader/cross.png" width=16 height=16>';
    } else if(value.match(/Uploaded/)) {
      return '<img src="/javascripts/extjs/awesome_uploader/tick.png" width=16 height=16>';
    } else if(value.match(/(Cancelled|Aborted)/)) {
      return '<img src="/javascripts/extjs/awesome_uploader/cross.png" width=16 height=16>';
    } else {
      return value;
    }
  },
    progressBarColumnTemplate = new Ext.XTemplate(
      '<div class="ux-progress-cell-inner ux-progress-cell-inner-center ux-progress-cell-foreground">',
        '<div>{value} %</div>',
      '</div>',
      '<div class="ux-progress-cell-inner ux-progress-cell-inner-center ux-progress-cell-background" style="left:{value}%">',
        '<div style="left:-{value}%">{value} %</div>',
      '</div>'
      ),  
    progressBarColumnRenderer = function(value, meta, record, rowIndex, colIndex, store){
      meta.css += ' x-grid3-td-progress-cell';
        return progressBarColumnTemplate.apply({
        value: value
      });
    },
    updateFileUploadRecord = function(id, column, value){
      var rec = AwesomeUploaderInstance3.awesomeUploaderGrid.store.getById(id);
      rec.set(column, value);
      rec.commit();
    };

    AwesomeUploaderInstance3 = new Ext.Window({
      title:'New Media Uploader',
      closeAction:'hide',
      onHide: function(){
        this.awesomeUploader.removeAllUploads();
      },
      frame:true,
      width:600,
      height:300,
      items:[{
        xtype:'awesomeuploader',
        ref:'awesomeUploader',
        extraPostData:{current_user_id: jQuery('.current_user_id').val() },
        height:40,
        allowDragAndDropAnywhere:true,
        xhrSendMultiPartFormData:true,
        xhrFilePostName:	'Filedata',
        autoStartUpload:false,
        maxFileSizeBytes: 30 * 1024 * 1024, // 30 MiB
        awesomeUploaderRoot: '/javascripts/extjs/awesome_uploader/',
        standardUploadUrl: '/media/upload',
        flashUploadUrl: '/media/upload',
        xhrUploadUrl: '/media/upload/true',
        listeners:{
          scope:this,
          fileselected:function(awesomeUploader, file){
            console.log(file);
            var matched_parts = file.name.match(/.*\.(jpe?g|gif|png|txt|mov|mp4|m4v|avi|mpeg|mpg|webm|ogv|mkv|mp3)$/i)
            if( !matched_parts ){	
              var wrong_file_format = file.name.match(/.*\.(.*)$/);
              if( wrong_file_format == null ) {
                Ext.Msg.alert('Error','You cannot upload a file with no file extension');
              } else {
                Ext.Msg.alert('Error','You cannot upload a file with .' + wrong_file_format[1] + ' file extension');
              }
              return false;
            }
            selected_files++;
            AwesomeUploaderInstance3.awesomeUploaderGrid.store.loadData({
              id:file.id,
              name:file.name,
              size:file.size,
              status:'Pending',
              progress:0,
            }, true);
          },
          uploadstart:function(awesomeUploader, file){
            updateFileUploadRecord(file.id, 'status', 'Sending');
          },
          uploadprogress:function(awesomeUploader, fileId, bytesComplete, bytesTotal){
            updateFileUploadRecord(fileId, 'progress', Math.round((bytesComplete / bytesTotal)*100) );
          },
          uploadcomplete:function(awesomeUploader, file, serverData, resultObject){
            try {
              var result = Ext.util.JSON.decode(serverData);
            } catch(e) {
              resultObject.error = 'Invalid JSON data returned';
              //Invalid json data. Return false here and "uploaderror" event will be called for this file. Show error message there.
              return false;
            }
            resultObject = result;
            if(result.success == "true"){
              updateFileUploadRecord(file.id, 'progress', 100 );
              updateFileUploadRecord(file.id, 'status', 'Uploaded' );
              uploaded_files++;
              uploaded.push({path:result.path,type:result.type});
            } else {
              selected_files--;
              //updateFileUploadRecord(file.id, 'progress', 0 );
              AwesomeUploaderInstance3.awesomeUploader.fireEvent('uploaderror', AwesomeUploaderInstance3.awesomeUploader, Ext.apply({}, AwesomeUploaderInstance3.awesomeUploader.fileQueue[file.id]), {}, result);
              //updateFileUploadRecord(file.id, 'status', result.error);
            }
            if(uploaded_files == selected_files && uploaded_files != 0){
              AwesomeUploaderInstance3.awesomeUploader.removeAllUploads();
              AwesomeUploaderInstance3.hide();
              $('#media-update-process').hide();
              showAddMetaInfoWin();
            }
          },
          uploadaborted:function(awesomeUploader, file ){
            updateFileUploadRecord(file.id, 'status', 'Aborted' );
          },
          uploadremoved:function(awesomeUploader, file ){
            AwesomeUploaderInstance3.awesomeUploaderGrid.store.remove(AwesomeUploaderInstance3.awesomeUploaderGrid.store.getById(file.id) );
          },
          uploaderror:function(awesomeUploader, file, serverData, resultObject){
            resultObject = resultObject || {};
            var error = 'Error';
            if(resultObject.error){
              error += ': ' + resultObject.error;
            }
            updateFileUploadRecord(file.id, 'progress', 0 );
            updateFileUploadRecord(file.id, 'status', error );
          },
        }
      }, {
        xtype:'grid',
        ref:'awesomeUploaderGrid',
        width:590,
        height:227,
        enableHdMenu:false,
        tbar:[{
          text:'Start Upload',
          icon:'/javascripts/extjs/awesome_uploader/tick.png',
          scope:this,
          handler:function(){
            AwesomeUploaderInstance3.awesomeUploader.startUpload();
          }
        }, {
          text:'Remove',
          icon:'/javascripts/extjs/awesome_uploader/cross.png',
          scope:this,
          handler:function(){
            var selModel = AwesomeUploaderInstance3.awesomeUploaderGrid.getSelectionModel();
            if(!selModel.hasSelection()){
              Ext.Msg.alert('','Please select an upload to cancel');
              return true;
            }
            var rec = selModel.getSelected();
            AwesomeUploaderInstance3.awesomeUploader.removeUpload(rec.data.id);
			      selected_files--;
          }
        },{
          text:'Remove All',
          icon:'/javascripts/extjs/awesome_uploader/cross.png',
          scope:this,
          handler:function(){
            AwesomeUploaderInstance3.awesomeUploader.removeAllUploads();
			      selected_files = 0;
          }
        }],
      store:new Ext.data.JsonStore({
        fields: ['id','name','size','status','progress'],
        idProperty: 'id'
      }),
      columns:[
        {header:'File Name',dataIndex:'name', width:230},
        {header:'Size',dataIndex:'size', width:60, renderer:Ext.util.Format.fileSize},
        {header:'&nbsp;',dataIndex:'status', width:30, renderer:statusIconRenderer},
        {header:'Status',dataIndex:'status', width:150},
        {header:'Progress',dataIndex:'progress', renderer:progressBarColumnRenderer}
      ]
      }]
    });
});
