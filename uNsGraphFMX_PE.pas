unit uNsGraphFMX_PE;

interface

uses
  System.Classes, DesignIntf, DesignEditors, uNsGraphFMX, DB;

type
  TDBFieldProperty = class(TStringProperty)
    function GetAttributes: TPropertyAttributes; override;
    procedure GetValues(Proc: TGetStrProc); override;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterPropertyEditor(TypeInfo(String), TNsGraph, 'DateField', TDBFieldProperty);
  RegisterPropertyEditor(TypeInfo(String), TNsGraph, 'KeyField', TDBFieldProperty);
  RegisterPropertyEditor(TypeInfo(String), TNsGraph, 'ValueField', TDBFieldProperty);
  RegisterPropertyEditor(TypeInfo(String), TNsGraph, 'NameField', TDBFieldProperty);
  RegisterPropertyEditor(TypeInfo(String), TNsGraph, 'ColorField', TDBFieldProperty);
end;

{ TDBFieldProperty }

function TDBFieldProperty.GetAttributes: TPropertyAttributes;
begin
  Result := [paValueList, paSortList, paAutoUpdate];
end;

procedure TDBFieldProperty.GetValues(Proc: TGetStrProc);
var
  Fld: TField;
begin
  if Assigned(TNsGraph(GetComponent(0)).DataSet) then
  begin
    for Fld in TNsGraph(GetComponent(0)).DataSet.Fields do
      Proc(Fld.DisplayName);
  end;
end;

end.
