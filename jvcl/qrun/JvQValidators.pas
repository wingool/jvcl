{**************************************************************************************************}
{  WARNING:  JEDI preprocessor generated unit. Manual modifications will be lost on next release.  }
{**************************************************************************************************}

{-----------------------------------------------------------------------------
The contents of this file are subject to the Mozilla Public License
Version 1.1 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at
http://www.mozilla.org/MPL/MPL-1.1.html

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either expressed or implied. See the License for
the specific language governing rights and limitations under the License.

The Original Code is: JvValidators.PAS, released on 2003-01-01.

The Initial Developer of the Original Code is Peter Th�rnqvist [peter3@peter3.com] .
Portions created by Peter Th�rnqvist are Copyright (C) 2003 Peter Th�rnqvist.
All Rights Reserved.

Contributor(s):

Last Modified: 2003-01-01

You may retrieve the latest version of this file at the Project JEDI's JVCL home page,
located at http://jvcl.sourceforge.net

Known Issues:
-----------------------------------------------------------------------------}

{$I jvcl.inc}

unit JvQValidators;

interface
uses
  SysUtils, Classes,
  
  
  QControls, QForms,
  
  JvQComponent, JvQErrorIndicator, JvQFinalize;

type
  EValidatorError = class(Exception);
  // Implemented by classes that can return the value to validate against.
  // The validator classes first check if the ControlToValidate supports this interface
  // and if it does, uses the value returned from GetValidationPropertyValue instead of
  // extracting it from RTTI (using ControlToValidate and PropertyToValidate)
  // The good thing about implementing this interface is that the value to validate do
  // not need to be a published property but can be anything, even a calculated value
  IJvValidationProperty = interface
    ['{564FD9F5-BE57-4559-A6AF-B0624C956E50}']
    function GetValidationPropertyValue: Variant;
    function GetValidationPropertyName: WideString;
  end;

  IJvValidationSummary = interface
    ['{F2E4F4E5-E831-4514-93C9-0E2ACA941DCF}']
    procedure BeginUpdate;
    procedure EndUpdate;
    procedure AddError(const ErrorMessage: string);
    procedure RemoveError(const ErrorMessage: string);
  end;

  TJvBaseValidator = class;
  TJvValidators = class;
  TJvBaseValidatorClass = class of TJvBaseValidator;

  TJvBaseValidator = class(TJvComponent)
  private
    FEnabled, FValid: boolean;
    FPropertyToValidate: string;
    FErrorMessage: string;
    FControlToValidate: TControl;
    FValidator: TJvValidators;
    FOnValidateFailed: TNotifyEvent;
    procedure SetControlToValidate(Value: TControl);
  protected
    function GetValidationPropertyValue: Variant; virtual;
    procedure SetValid(const Value: boolean); virtual;
    function GetValid: Boolean; virtual;
    procedure DoValidateFailed; dynamic;
    procedure Validate; virtual; abstract;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure SetParentComponent(Value: TComponent); override;
    procedure ReadState(Reader: TReader); override;

    // get the number of registered base validator classes
    class function BaseValidatorsCount:integer;
    // get info on a registered class
    class procedure GetBaseValidatorInfo(Index:integer;var DisplayName:String;var ABaseValidatorClass:TJvBaseValidatorClass);
  public
    // register a new base validator class. DisplayName is used by the design-time editor.
    // A class with an empty DisplayName will not sshow up in the editor
    class procedure RegisterBaseValidator(const DisplayName:string; AValidatorClass:TJvBaseValidatorClass);

    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function GetParentComponent: TComponent; override;
    function HasParent: Boolean; override;


    property Value: Variant read GetValidationPropertyValue;
  published
    property Valid: boolean read GetValid write SetValid;
    // the control to validate
    property ControlToValidate: TControl read FControlToValidate write SetControlToValidate;
    // the property in ControlToValidate to validate against
    property PropertyToValidate: string read FPropertyToValidate write FPropertyToValidate;
    property Enabled: boolean read FEnabled write FEnabled;
    // the message to display in case of error
    property ErrorMessage: string read FErrorMessage write FErrorMessage;
    // triggered when Valid is set to false
    property OnValidateFailed: TNotifyEvent read FOnValidateFailed write FOnValidateFailed;
  end;

  TJvRequiredFieldValidator = class(TJvBaseValidator)
  protected
    procedure Validate; override;
  end;

  TJvValidateCompareOperator = (vcoLessThan, vcoLessOrEqual, vcoEqual, vcoGreaterOrEqual, vcoGreaterThan);

  TJvCompareValidator = class(TJvBaseValidator)
  private
    FValueToCompare: Variant;
    FOperator: TJvValidateCompareOperator;
  protected
    procedure Validate; override;
  published
    property ValueToCompare: Variant read FValueToCompare write FValueToCompare;
    property Operator: TJvValidateCompareOperator read FOperator write FOperator;
  end;

  TJvRangeValidator = class(TJvBaseValidator)
  private
    FMinimumValue: Variant;
    FMaximumValue: Variant;
  protected
    procedure Validate; override;
  published
    property MinimumValue: Variant read FMinimumValue write FMinimumValue;
    property MaximumValue: Variant read FMaximumValue write FMaximumValue;
  end;

  TJvRegularExpressionValidator = class(TJvBaseValidator)
  private
    FValidationExpression: string;
  protected
    procedure Validate; override;
  published
    property ValidationExpression: string read FValidationExpression write FValidationExpression;
  end;

  TJvCustomValidateEvent = procedure(Sender: TObject; ValueToValidate: Variant; var Valid: boolean) of object;

  TJvCustomValidator = class(TJvBaseValidator)
  private
    FOnValidate: TJvCustomValidateEvent;
  protected
    function DoValidate: boolean; virtual;
    procedure Validate; override;
  published
    property OnValidate: TJvCustomValidateEvent read FOnValidate write FOnValidate;
  end;

  TJvValidateFailEvent = procedure(Sender: TObject; BaseValidator: TJvBaseValidator; var Continue: boolean) of object;

  TJvValidators = class(TJvComponent)
  private
    FOnValidateFailed: TJvValidateFailEvent;
    FItems: TList;
    FValidationSummary: IJvValidationSummary;
    FErrorIndicator: IJvErrorIndicator;
    
    procedure SetValidationSummary(const Value: IJvValidationSummary);
    procedure SetErrorIndicator(const Value: IJvErrorIndicator);
    function GetCount: integer;
    function GetItem(Index: integer): TJvBaseValidator;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure GetChildren(Proc: TGetChildProc; Root: TComponent); override;
    function DoValidateFailed(const ABaseValidator: TJvBaseValidator): boolean; dynamic;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Insert(AValidator: TJvBaseValidator);
    procedure Remove(AValidator: TJvBaseValidator);
    procedure Exchange(Index1, Index2: integer);
    function Validate: boolean;
    property Items[Index: integer]: TJvBaseValidator read GetItem; default;
    property Count: integer read GetCount;
  published
    
    property ValidationSummary: IJvValidationSummary read FValidationSummary write SetValidationSummary;
    property ErrorIndicator:IJvErrorIndicator read FErrorIndicator write SetErrorIndicator;
    
    property OnValidateFailed: TJvValidateFailEvent read FOnValidateFailed write FOnValidateFailed;
  end;

  TJvValidationSummary = class(TJvComponent, IUnknown, IJvValidationSummary)
  private
    FUpdateCount: Integer;
    FPendingUpdates: Integer;
    FSummaries: TStringList;
    FOnChange: TNotifyEvent;
    FOnRemoveError: TNotifyEvent;
    FOnAddError: TNotifyEvent;
    function GetSummaries: TStrings;
  protected
    { IJvValidationSummary }
    procedure AddError(const ErrorMessage: string);
    procedure RemoveError(const ErrorMessage: string);
    procedure BeginUpdate;
    procedure EndUpdate;

    procedure Change; virtual;
  public
    destructor Destroy; override;
    property Summaries: TStrings read GetSummaries;
  published
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property OnAddError: TNotifyEvent read FOnAddError write FOnAddError;
    property OnRemoveError: TNotifyEvent read FOnRemoveError write FOnRemoveError;
  end;

implementation

uses
  
  Variants,
  
  TypInfo,
  JclUnicode, // for reg exp support
  JvQTypes, JvQResources;

const
  sUnitName = 'JvValidators';

var
  GlobalValidatorsList: TStringList = nil;

procedure RegisterBaseValidators; forward;

function ValidatorsList: TStringList;
begin
  if not Assigned(GlobalValidatorsList) then
  begin
    GlobalValidatorsList := TStringList.Create;
    AddFinalizeObjectNil(sUnitname, TObject(GlobalValidatorsList));
   // register
    RegisterBaseValidators;
  end;
  Result := GlobalValidatorsList;
end;

procedure Debug(const Msg: string); overload;
begin
//  Application.MessageBox(PChar(Msg),PChar('Debug'),MB_OK or MB_TASKMODAL)
end;

procedure Debug(const Msg: string; const Fmt: array of const); overload;
begin
  Debug(Format(Msg, Fmt));
end;

function ComponentName(Comp: TComponent): string;
begin
  if Comp = nil then
    Result := 'nil'
  else if Comp.Name <> '' then
    Result := Comp.Name
  else
    Result := Comp.ClassName;
end;



{ TJvBaseValidator }

class procedure TJvBaseValidator.RegisterBaseValidator(const DisplayName:string; AValidatorClass:TJvBaseValidatorClass);
begin
  if ValidatorsList.IndexOfObject(Pointer(AValidatorClass)) < 0 then
  begin
    Classes.RegisterClass(TPersistentClass(AValidatorClass));
    ValidatorsList.AddObject(DisplayName,Pointer(AValidatorClass));
  end;
end;

class function TJvBaseValidator.BaseValidatorsCount:integer;
begin
  Result := ValidatorsList.Count;
end;

class procedure TJvBaseValidator.GetBaseValidatorInfo(Index:integer;var DisplayName:string;var ABaseValidatorClass:TJvBaseValidatorClass);
begin
  if  (Index < 0) or (Index >= ValidatorsList.Count) then
    raise EJVCLException.CreateFmt(RsEInvalidIndexd, [Index]);
  DisplayName := ValidatorsList[Index];
  ABaseValidatorClass := TJvBaseValidatorClass(ValidatorsList.Objects[Index]);
end;

constructor TJvBaseValidator.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FValid := true;
  FEnabled := true;
end;

destructor TJvBaseValidator.Destroy;
begin
  Debug('TJvBaseValidator.Destroy: FValidator is %s', [ComponentName(FValidator)]);
  ControlToValidate := nil;
  if FValidator <> nil then
  begin
    FValidator.Remove(self);
    FValidator := nil;
  end;
  inherited Destroy; ;
end;

function TJvBaseValidator.GetValid: Boolean;
begin
  Result := FValid;
end;

function TJvBaseValidator.GetParentComponent: TComponent;
begin
  Debug('TJvBaseValidator.GetParentComponent: Parent is %s', [ComponentName(FValidator)]);
  Result := FValidator;
end;

function TJvBaseValidator.GetValidationPropertyValue: Variant;
var
  ValProp: IJvValidationProperty;
begin
  Result := NULL;
  if (FControlToValidate <> nil) then
  begin
    if Supports(FControlToValidate, IJvValidationProperty, ValProp) then
      Result := ValProp.GetValidationPropertyValue
    else if (FPropertyToValidate <> '') then
      Result := GetPropValue(FControlToValidate, FPropertyToValidate, false);
  end;
end;

function TJvBaseValidator.HasParent: Boolean;
begin
  Debug('TJvBaseValidator.HasParent');
  Result := true;
end;

procedure TJvBaseValidator.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) then
  begin
    if (AComponent = ControlToValidate) then
      ControlToValidate := nil;
  end;
end;

procedure TJvBaseValidator.SetValid(const Value: boolean);
begin
  FValid := Value;
  if not FValid then
    DoValidateFailed;
end;

procedure TJvBaseValidator.SetControlToValidate(Value: TControl);
var obj: IJvValidationProperty;
begin
  if FControlToValidate <> Value then
  begin
    if FControlToValidate <> nil then
      FControlToValidate.RemoveFreeNotification(self);
    FControlToValidate := Value;
    if FControlToValidate <> nil then
    begin
      FControlToValidate.FreeNotification(self);
      if Supports(FControlToValidate, IJvValidationProperty, obj) then
        PropertyToValidate := obj.GetValidationPropertyName;
    end;
  end;
end;

procedure TJvBaseValidator.SetParentComponent(Value: TComponent);
begin
  if not (csLoading in ComponentState) then
  begin
    Debug('TJvBaseValidator.SetParentComponent: Parent is %s, changing to %s',
      [ComponentName(FValidator), ComponentName(Value)]);
    if FValidator <> nil then
    begin
      Debug('FValidator.Remove');
      FValidator.Remove(self);
    end;
    if (Value <> nil) and (Value is TJvValidators) then
    begin
      Debug('FValidator.Insert');
      TJvValidators(Value).Insert(self);
    end;
  end;
end;

procedure TJvBaseValidator.ReadState(Reader: TReader);
begin
  inherited;
  Debug('TJvBaseValidator.ReadState: Reader.Parent is %s', [ComponentName(Reader.Parent)]);
  if Reader.Parent is TJvValidators then
  begin
    if FValidator <> nil then
      FValidator.Remove(self);
    FValidator := TJvValidators(Reader.Parent);
    FValidator.Insert(self);
  end;
end;

procedure TJvBaseValidator.DoValidateFailed;
begin
  if Assigned(FOnValidateFailed) then
    FOnValidateFailed(self);
end;

{ TJvRequiredFieldValidator }

procedure TJvRequiredFieldValidator.Validate;
var
  R: Variant;
begin
  R := GetValidationPropertyValue;
  Valid := VarCompareValue(R, '') <> vrEqual;
end;

{ TJvCustomValidator }

function TJvCustomValidator.DoValidate: boolean;
begin
  Result := Valid;
  if Assigned(FOnValidate) then
    FOnValidate(self, GetValidationPropertyValue, Result);
end;

procedure TJvCustomValidator.Validate;
begin
  Valid := DoValidate;
end;

{ TJvRegularExpressionValidator }

function MatchesMask(const Filename, Mask: string; const SearchFlags: TSearchFlags = [sfCaseSensitive]): boolean;
var
  URE: TURESearch;
  SL: TWideStringList;
begin
  // use the regexp engine in JclUnicode
  SL := TWideStringList.Create;
  try
    URE := TURESearch.Create(SL);
    try
      URE.FindPrepare(Mask, SearchFlags);
      // this could be overkill for long strings and many matches,
      // but it's a lot simpler than calling FindFirst...
      Result := URE.FindAll(Filename);
    finally
      URE.Free;
    end;
  finally
    SL.Free;
  end;
end;

procedure TJvRegularExpressionValidator.Validate;
var
  R: string;
begin
  R := VarToStr(GetValidationPropertyValue);
  Valid := (R = ValidationExpression) or MatchesMask(R, ValidationExpression);
end;

{ TJvCompareValidator }

procedure TJvCompareValidator.Validate;
var
  VR: TVariantRelationship;
begin
  VR := VarCompareValue(GetValidationPropertyValue, ValueToCompare);
  case Operator of
    vcoLessThan:
      Valid := VR = vrLessThan;
    vcoLessOrEqual:
      Valid := (VR = vrLessThan) or (VR = vrEqual);
    vcoEqual:
      Valid := (VR = vrEqual);
    vcoGreaterOrEqual:
      Valid := (VR = vrGreaterThan) or (VR = vrEqual);
    vcoGreaterThan:
      Valid := (VR = vrGreaterThan);
  end;
end;

{ TJvRangeValidator }

procedure TJvRangeValidator.Validate;
var
  VR: TVariantRelationship;
begin
  VR := VarCompareValue(GetValidationPropertyValue, MinimumValue);
  Valid := (VR = vrGreaterThan) or (VR = vrEqual);
  if Valid then
  begin
    VR := VarCompareValue(GetValidationPropertyValue, MaximumValue);
    Valid := (VR = vrLessThan) or (VR = vrEqual);
  end;
end;

{ TJvValidators }

constructor TJvValidators.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FItems := TList.Create;
end;

destructor TJvValidators.Destroy;
var V: TJvBaseValidator;
begin
  Debug('TJvValidators.Destroy: Count is %d', [FItems.Count]);
  while FItems.Count > 0 do
  begin
    V := TJvBaseValidator(FItems.Last);
    V.FValidator := nil;
    V.Free;
    FItems.Delete(FItems.Count - 1);
  end;
  FItems.Free;
  inherited;
end;

function TJvValidators.DoValidateFailed(
  const ABaseValidator: TJvBaseValidator): boolean;
begin
  Result := true;
  if Assigned(FOnValidateFailed) then
    FOnValidateFailed(self, ABaseValidator, Result);
  
end;

function TJvValidators.Validate: boolean;
var i: integer;
begin
  Result := true;
  if ValidationSummary <> nil then
    FValidationSummary.BeginUpdate;
  try
    for i := 0 to Count - 1 do
    begin
      Items[i].Validate;
      if not Items[i].Valid then
      begin
        if (Items[i].ErrorMessage <> '') and (Items[i].ControlToValidate <> nil) then
        begin
          if ValidationSummary <> nil then
            FValidationSummary.AddError(Items[i].ErrorMessage);
          if ErrorIndicator <> nil then
            FErrorIndicator.SetError(Items[i].ControlToValidate,Items[i].ErrorMessage);
        end;
        Result := false;
        if not DoValidateFailed(Items[i]) then
          Exit;
      end;
    end;
  finally
    if ValidationSummary <> nil then
      FValidationSummary.EndUpdate;
  end;
end;

procedure TJvValidators.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited;
  if Operation = opRemove then
  begin
    
    if (Assigned(ValidationSummary)) and (AComponent.IsImplementorOf(ValidationSummary)) then
      ValidationSummary := nil;
    if (Assigned(ErrorIndicator)) and (AComponent.IsImplementorOf(ErrorIndicator)) then
      ErrorIndicator := nil;
    
  end;
end;

procedure TJvValidators.GetChildren(Proc: TGetChildProc; Root: TComponent);
var i: integer;
begin
  Debug('TJvValidators.GetChildren: Count is %d, Root is %s', [Count, ComponentName(Root)]);
  for i := 0 to Count - 1 do
    Proc(Items[i]);
end;

procedure TJvValidators.SetValidationSummary(const Value: IJvValidationSummary);
begin
  
  ReferenceInterface(FValidationSummary, opRemove);
  FValidationSummary := Value;
  ReferenceInterface(FValidationSummary, opInsert);
  
end;



procedure TJvValidators.Insert(AValidator: TJvBaseValidator);
begin
  Debug('TJvValidators.Insert: inserting %s', [ComponentName(AValidator)]);
  Assert(AValidator <> nil, RsEInsertNilValidator);
  AValidator.FValidator := self;
  if FItems.IndexOf(AValidator) < 0 then
    FItems.Add(AValidator);
end;

procedure TJvValidators.Remove(AValidator: TJvBaseValidator);
begin
  Debug('TJvValidators.Remove: removing %s', [ComponentName(AValidator)]);
  Assert(AValidator <> nil, RsERemoveNilValidator);
  Assert(AValidator.FValidator = self, RsEValidatorNotChild);
  AValidator.FValidator := nil;
  FItems.Remove(AValidator);
end;

function TJvValidators.GetCount: integer;
begin
  Result := FItems.Count;
end;

function TJvValidators.GetItem(Index: integer): TJvBaseValidator;
begin
  Result := TJvBasevalidator(FItems[Index]);
end;

procedure TJvValidators.Exchange(Index1, Index2: integer);
begin
  FItems.Exchange(Index1, Index2);
end;

procedure TJvValidators.SetErrorIndicator(const Value: IJvErrorIndicator);
begin
  
  ReferenceInterface(FErrorIndicator, opRemove);
  FErrorIndicator := Value;
  ReferenceInterface(FErrorIndicator, opInsert);
  
end;

{ TJvValidationSummary }

procedure TJvValidationSummary.AddError(const ErrorMessage: string);
begin
  if Summaries.IndexOf(ErrorMessage) < 0 then
  begin
    Summaries.Add(ErrorMessage);
    if (FUpdateCount = 0) and Assigned(FOnAddError) then
      FOnAddError(self);
    Change;
  end;
end;

procedure TJvValidationSummary.RemoveError(const ErrorMessage: string);
var i: Integer;
begin
  i := Summaries.IndexOf(ErrorMessage);
  if i > -1 then
  begin
    Summaries.Delete(i);
    if (FUpdateCount = 0) and Assigned(FOnRemoveError) then
      FOnRemoveError(self);
    Change;
  end;
end;

destructor TJvValidationSummary.Destroy;
begin
  FSummaries.Free;
  inherited Destroy;
end;

function TJvValidationSummary.GetSummaries: TStrings;
begin
  if FSummaries = nil then
    FSummaries := TStringList.Create;
  Result := FSummaries;
end;

procedure TJvValidationSummary.Change;
begin
  if FUpdateCount <> 0 then
  begin
    Inc(FPendingUpdates);
    Exit;
  end;
  if Assigned(FOnChange) then
    FOnChange(self);
end;

procedure TJvValidationSummary.BeginUpdate;
begin
  Inc(FUpdateCount);
end;

procedure TJvValidationSummary.EndUpdate;
begin
  Dec(FUpdateCount);
  if FUpdateCount < 0 then
    FUpdateCount := 0;
  if (FUpdateCount = 0) and (FPendingUpdates > 0) then
  begin
    Change;
    FPendingUpdates := 0;
  end;
end;

procedure RegisterBaseValidators;
begin
  TJvBaseValidator.RegisterBaseValidator('Required Field Validator', TJvRequiredFieldValidator);
  TJvBaseValidator.RegisterBaseValidator('Compare Validator', TJvCompareValidator);
  TJvBaseValidator.RegisterBaseValidator('Range Validator', TJvRangeValidator);
  TJvBaseValidator.RegisterBaseValidator('Regular Expression Validator', TJvRegularExpressionValidator);
  TJvBaseValidator.RegisterBaseValidator('Custom Validator', TJvCustomValidator);
end;

initialization
//  RegisterClasses([TJvValidators, TJvValidationSummary]);

finalization
  FinalizeUnit(sUnitName);

end.


