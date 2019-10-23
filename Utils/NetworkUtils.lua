LICENSE = [[
FileName: NetworkUtils.lua
Author: SmallDi
Version: 1.0.0
Date: 2019-10-24
Email: 1753520469@qq.com
Github: https://github.com/smalldi/LuaJavaUtils/Utils/NetworkUtils.lua
Description: 纯LuaJava代码编写的高度自定义对话框

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


local NetworkUtils = {}

--获取网络状态
function NetworkUtils:getNetworkState()
  import "android.net.ConnectivityManager"
  local networkType = -1;
  local systemService = this.getSystemService(Context.CONNECTIVITY_SERVICE);
  local networkInfo = systemService.getActiveNetworkInfo();
  if networkInfo == nil then
    return networkType;
  end
  local type = networkInfo.getType();
  if type == ConnectivityManager.TYPE_MOBILE then
    networkType = 2;
   elseif type == ConnectivityManager.TYPE_WIFI then
    networkType = 1;
  end
  return networkType;
end

--获取网络类型
function NetworkUtils:getNetworkType()
  local state = self:getNetworkState()
  switch state
   case -1
    return "NOT"
   case 1
    return "WIFI"
   case 2
    return "MOBILE"
  end
end

--判断是否为VPN网络
function NetworkUtils:isVpnUsed()
  import "java.net.NetworkInterface"
  local networkiList = NetworkInterface.getNetworkInterfaces();
  if networkiList ~= nil then
    local it = Collections.list(networkiList).iterator();
    while it.hasNext() do
      local intf = it.next();
      if intf.isUp() and intf.getInterfaceAddresses().size() ~= 0 then
        if String("tun0").equals(intf.getName()) or String("ppp0").equals(intf.getName()) then
          return true;
        end
      end
    end
  end
  return false;
end


