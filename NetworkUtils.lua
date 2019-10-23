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


