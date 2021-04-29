# FormCustomizationHelper
窗口自定义助手

# 调用示例:
```Delphi
procedure TForm2.DoIdle(Sender: TObject; var Done: Boolean);
begin
  Self.Invalidate;
end;

procedure TForm2.FormCreate(Sender: TObject);
begin
  Application.OnIdle:= DoIdle;
  FCustomizationHelper:= TFormCustomizationHelper.Create(Self);
end;
```

# 效果图:

![fmxformresize screenshot](https://github.com/se-looper/FormCustomizationHelper/blob/main/delphi_fmx_resize.gif)
