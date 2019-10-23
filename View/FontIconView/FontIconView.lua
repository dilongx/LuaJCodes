require "import"
import "java.io.File"
import "android.widget.TextView"
import "android.graphics.Typeface"

--字体图标控件
function FontIconView(view)
  local path = File(this.getLuaDir(view.fontpath))
  local font = Typeface.createFromFile(path)

  local FontIconView=loadlayout{
    TextView,--封装属性
    id=view.id,
    Typeface=font,
    text=view.icon,
    gravity="center",
    TextSize=view.size,
    TextColor=view.color,
    contentDescription=view.title,
  }
  if view.title ~= nil then
    FontIconView.onLongClick=function(view)
      print(view.contentDescription)
      return true
    end
  end
  return function()
    return FontIconView 
  end
end


