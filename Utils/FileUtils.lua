LICENSE = [[
FileName: FileUtils.lua
Author: SmallDi
Version: 1.0.0
Date: 2019-10-24
Email: 1753520469@qq.com
Github: https://github.com/smalldi/LuaJavaUtils/Utils/FileUtils.lua
Description: 文件处理工具模块

Copyright (C) 2019. SmallDi. All Rights Reserved.

Licensed under the GNU GENERAL PUBLIC LICENSE Version 3, (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

https://www.gnu.org/licenses/gpl-3.0.txt

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
]]


require "import"
import "java.io.File"
import "android.net.Uri"
import "android.app.Activity"
import "android.os.Environment"
import "android.content.Intent"
import "android.widget.TextView"
import "android.content.Context"
import "android.widget.ProgressBar"
import "android.webkit.MimeTypeMap"
import "android.provider.MediaStore"
import "android.content.ContentUris"
import "java.util.logging.Formatter"
import "android.widget.LinearLayout"
import "android.app.DownloadManager"
import "android.content.IntentFilter"
import "android.content.ContentResolver"
import "android.app.DownloadManager$Query"
import "android.provider.DocumentsContract"
import "android.provider.MediaStore$MediaColumns"


FileUtils = {}


--检查文件
function FileUtils:check(path)
  local file=io.open(path,"r")
  if not file then
    return false
  else
    file:close()
    return true
  end
end


--写入文件
function FileUtils:write(path,string)
  import "java.io.File"
  local file = File(tostring(path))
  file.getParentFile().mkdirs()
  local open = io.open(tostring(path),"w")
  local open = open:write(tostring(string))
  local open = open:close()
  return self
end


--读取文件
function FileUtils:read(path)
  local file=io.open(path,"r")
  if file then
    local str=file:read("*a")
    file:close()
    return str
  else
    return nil
  end
end


--复制文件
function FileUtils:copy(path1,path2)
  local file = File(tostring(path2))
  file.getParentFile().mkdirs()
  LuaUtil.copyDir(File(path1),file)
  return self
end


--重命名文件
function FileUtils:rename(dir,name)
  local path = File(dir).getParentFile()
  File(dir).renameTo(File(path.."/"..name))
  return self
end


--获取MIME样式
function FileUtils:getMimeType(extension)
  local MimeType = MimeTypeMap.getSingleton()
  MimeType.getMimeTypeFromExtension(extension)
end


--获取大小
function FileUtils:getSize(path)
  local size = File(tostring(path)).length()
  return Formatter.formatFileSize(this, size)
end


--分享文件
function FileUtils:ShareFile(path)
  local ExtensionName=tostring(path):match("[^.]+$")
  local MimeType = MimeTypeMap.getSingleton()
  local intent = Intent(Intent.ACTION_SEND)
  intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
  intent.putExtra(Intent.EXTRA_STREAM,Uri.fromFile(File(path)))
  intent.setType(MimeType.getMimeTypeFromExtension(ExtensionName))
  activity.startActivity(intent)
end


--打开文件
function FileUtils:OpenFile(path)
  local ExtensionName = tostring(path):match("[^.]+$")
  local MimeType = MimeTypeMap.getSingleton().getMimeTypeFromExtension(ExtensionName)
  if MimeType then
    intent = Intent(Intent.ACTION_VIEW)
    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
    intent.setDataAndType(Uri.fromFile(File(path)), MimeType);
    activity.startActivity(intent)
    return true
  else
    return false
  end
end


--查询数据库
function FileUtils:getDataColumn(uri, projection,selection,selectionArgs,sortOrder)

  local managedQuery = activity.ContentResolver.query
  local cursor = managedQuery(uri, projection,selection,selectionArgs,sortOrder)

  if cursor ~= nil and cursor.moveToFirst() then

    return cursor.getString(cursor.getColumnIndexOrThrow(projection[1]))

  end if cursor ~= nil then cursor.close() end return nil
end


--URI转路径
function FileUtils:getFilePath(uri)

  if DocumentsContract.isDocumentUri(activity, uri) then

    if String("com.android.externalstorage.documents").equals(uri.getAuthority()) then

      local documentId = DocumentsContract.getDocumentId(uri);
      local documentId = String(documentId).split(":");
      local type,id = documentId[0],documentId[1]

      if String("primary").equalsIgnoreCase(type) then

        return Environment.getExternalStorageDirectory().toString().."/"..id

      end

    elseif String("com.android.providers.downloads.documents").equals(uri.getAuthority()) then

      local documentId = DocumentsContract.getDocumentId(uri);
      local contentUri = ContentUris.withAppendedId(Uri.parse("content://downloads/public_downloads"), Long.valueOf(documentId));
      return self:getDataColumn(contentUri, {MediaColumns.DATA});


    elseif String("com.android.providers.media.documents").equals(uri.getAuthority()) then

      local documentId = DocumentsContract.getDocumentId(uri);
      local documentId = String(documentId).split(":");
      local type,id = documentId[0],documentId[1]

      if String("image").equals(type) then

        contentUri = MediaStore.Images.Media.EXTERNAL_CONTENT_URI;

      elseif String("video").equals(type) then

        contentUri = MediaStore.Video.Media.EXTERNAL_CONTENT_URI;

      elseif String("audio").equals(type) then

        contentUri = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI;

      end

      return self:getDataColumn(contentUri, {MediaColumns.DATA}, "_id=?", {id});

    end
  elseif String(ContentResolver.SCHEME_CONTENT).equalsIgnoreCase(uri.getScheme()) then

    return self:getDataColumn(uri, {MediaColumns.DATA});

  elseif String(ContentResolver.SCHEME_FILE).equalsIgnoreCase(uri.getScheme()) then

    return uri.getPath();
  end

end


--文件选择器
local ERROR_HEAD = {"该MimeType不存在：","该Uri无效或处理失败："}
function FileUtils:choose(type,Callback)
  local intent = Intent(Intent.ACTION_GET_CONTENT)
  intent.setType(self:getMimeType(type) or type)
  intent.addCategory(Intent.CATEGORY_OPENABLE)
  local status,error = pcall(function()
    activity.startActivityForResult(intent,1)
  end)if not status then this.showToast(ERROR_HEAD[1]..error) end
  function onActivityResult(requestCode,resultCode,data)
    if resultCode == Activity.RESULT_OK then
      if requestCode == 1 then local uri = data.getData()
        local status,error = pcall(function()return self:getFilePath(uri)end)
        if error == nil then this.showToast(ERROR_HEAD[2]..tostring(uri)) else
          if status then Callback(error,uri)else this.showToast(ERROR_HEAD[2]..error) end
        end
      end
    end
  end
end


--设置进度
local function UpdateUI(Status,fileByte,fileSize)
  local percentage = tointeger(fileByte * 100 / fileSize)
  local totalSize = tostring(string.format("%0.2f",fileSize/1024/1024).."MB")
  local currentSize = tostring(string.format("%0.2f",fileByte/1024/1024).."MB")
  switch(Status)
    case 8
    status.Text = "已完成！"
    sizeStatus.Text = totalSize.."/"..totalSize
    progress.progress = percentage * 100
    FileUtils:hideProgress()

    case 4
    status.Text = "等待中！"

    case 2
    status.Text = "下载中！"
    progress.progress = percentage
    sizeStatus.Text = currentSize.."/"..totalSize

  end

end


--下载文件
function FileUtils:download(url,path,bool,callback)

  self.progressDialog = LuaDialog(this){
    view=loadlayout{
      LinearLayout,
      padding="16dp";
      layout_width="fill",
      layout_height="fill",
      orientation="vertical",
      {
        ProgressBar,
        id="progress",
        layout_width="fill",
        style="?android:attr/progressBarStyleHorizontal",
      },
      {
        LinearLayout;
        layout_width="fill",
        layout_height="fill",
        {
          TextView;
          id="sizeStatus",
          text="00MB/00MB"
        },
        {
          TextView;
          id="status",
          gravity="right";
          layout_weight="1"
        }
      }
    },
    Cancelable=false

  }


  local request = DownloadManager.Request(Uri.parse(url))
  request.setVisibleInDownloadsUi(Boolean.valueOf(bool))
  request.setDestinationUri(Uri.fromFile(File(path)));
  request.setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED);
  request.setAllowedNetworkTypes(DownloadManager.Request.NETWORK_MOBILE|DownloadManager.Request.NETWORK_WIFI);
  downloadManager = activity.getSystemService(Context.DOWNLOAD_SERVICE)
  local reference = downloadManager.enqueue(request);

  thread(function(downloadManager,reference)
    require "import"
    import "android.app.DownloadManager"
    import "android.app.DownloadManager$Query"
    local downloadQuery = Query().setFilterById(long{reference});
    while true do
      local cursor = downloadManager.query(downloadQuery); 
      if cursor.moveToNext() then
        local Status = cursor.getLong(cursor.getColumnIndex(DownloadManager.COLUMN_STATUS));
        local fileSize = cursor.getLong(cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_TOTAL_SIZE_BYTES)); 
        local fileByte = cursor.getLong(cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_BYTES_DOWNLOADED_SO_FAR)); 

        call("UpdateUI",Status,fileByte,fileSize)
      end
      Thread.sleep(1000)
    end
  end,downloadManager,reference)


  --注册广播
  local intentFilter = IntentFilter();
  intentFilter.addAction(DownloadManager.ACTION_DOWNLOAD_COMPLETE);
  local broadcastReceiver = LuaBroadcastReceiver.OnReceiveListerer({
    onReceive=function(context, intent)
      local downloadId = intent.getLongExtra(DownloadManager.EXTRA_DOWNLOAD_ID, -1)
      switch(intent.getAction())
        case DownloadManager.ACTION_DOWNLOAD_COMPLETE --下载完成
        if downloadId == reference then

          local downloadQuery = Query().setFilterById(long{reference});
          local cursor = downloadManager.query(downloadQuery); 
          if cursor.moveToFirst() then

            local fileUri = cursor.getString(cursor.getColumnIndex(DownloadManager.COLUMN_LOCAL_URI)); 
            local filePath = cursor.getString(cursor.getColumnIndex(DownloadManager.COLUMN_LOCAL_FILENAME)); 
            local fileSize = cursor.getLong(cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_TOTAL_SIZE_BYTES)); 

            callback(filePath,fileUri,tostring(string.format("%0.2f",fileSize/1024/1024).."MB"),reference)
          end
        end

      end
    end
  })

  activity.registerReceiver(broadcastReceiver, intentFilter)
  return self
end


--显示进度
function FileUtils:showProgress()
  if self then self.progressDialog.show()end
  return self
end


--隐藏进度
function FileUtils:hideProgress()
  if self then self.progressDialog.hide()end
  return self
end


--删除下载
function FileUtils:remove(ids)
  downloadManager.remove(long{ids})
  return self
end


--重新下载
function FileUtils:restartDownload(ids)
  downloadManager.restartDownload(long{ids})
  return self
end


--获取Uri
function FileUtils:getUriForDownloadedFile(id)
  return downloadManager.getUriForDownloadedFile(id)
end


--获取类型
function FileUtils:getMimeTypeForDownloadedFile(id)
  return downloadManager.getMimeTypeForDownloadedFile(id)
end


--移动网络下载的最大字节
function FileUtils:getMaxBytesOverMobile()
  return downloadManager.getMaxBytesOverMobile(this)
end


--移动网络建议下载的大小
function FileUtils:getRecommendedMaxBytesOverMobile()
  return downloadManager.getRecommendedMaxBytesOverMobile(this)
end


--添加文件到下载数据库中
function FileUtils:addCompletedDownload(title, description,isMediaScannerScannable, mimeType, path, length, showNotification)
  return downloadManager.addCompletedDownload(title, description,isMediaScannerScannable, mimeType, path, length, showNotification)
end


