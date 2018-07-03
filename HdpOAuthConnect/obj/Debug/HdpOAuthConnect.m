section HdpOAuthConnect;

[DataSource.Kind="HdpOAuthConnect", Publish="HdpOAuthConnect.Publish"]
shared HdpOAuthConnect.Contents = (optional message as text) =>
let
source = OData.Feed(
"http://nc-supplnx-ce6.americas.progress.com:8080/api/odata4/sqlserver",
null,
[ ODataVersion = 4, MoreColumns = true ])
in
source;

// Data Source Kind description
HdpOAuthConnect = [
Authentication = [
OAuth = [
StartLogin = StartLogin,
FinishLogin = FinishLogin,
Label = "HDP OAuth2"
]
],
Label = Extension.LoadString("DataSourceLabel")
];

client_id = "de15456e-70d5-4f66-a868-52271244fe63"; 
client_secret = "fac3e242-9ac5-4bcb-b3bb-f63863eefe79";
redirect_uri = "https://preview.powerbi.com/views/oauthredirect.html";
windowWidth = 1200;
windowHeight = 1000;

StartLogin = (resourceUrl, state, display) =>
let
AuthorizeUrl = "http://nc-supplnx-ce6.americas.progress.com:8080/oauth2/authorize?" & Uri.BuildQueryString([
client_id = client_id,
state = state,
response_type = "code",
scope="api.access.odata ",
redirect_uri = redirect_uri])
in
[
LoginUri = AuthorizeUrl,
CallbackUri = redirect_uri,
WindowHeight = windowHeight,
WindowWidth = windowWidth,
Context = null
];

FinishLogin = (context, callbackUri, state) =>
let
parts = Uri.Parts(callbackUri)[Query],
result = if (Record.HasFields(parts, {"error", "error_description"})) then
error Error.Record(parts[error], parts[error_description], parts)
else
TokenMethod("authorization_code", parts[code])
in
result;

TokenMethod = (grantType, code) =>
let
query = [
client_id = client_id,
client_secret = client_secret,
code = code,
grant_type = "authorization_code",
redirect_uri = redirect_uri],

queryWithCode = if (grantType = "refresh_token") then [ refresh_token = code ] else [code = code],

Response = Web.Contents("http://nc-supplnx-ce6.americas.progress.com:8080/oauth2/token", [
Content = Text.ToBinary(Uri.BuildQueryString(query & queryWithCode)),
Headers=[#"Content-type" = "application/x-www-form-urlencoded",#"Accept" = "application/json"], ManualStatusHandling = {400}]),


Parts = Json.Document(Response),

Result = if (Record.HasFields(Parts, {"error", "error_description"})) then
error Error.Record(Parts[error], Parts[error_description], Parts)
else
Parts
in
Result;

Refresh = (resourceUrl, refresh_token) => TokenMethod("refresh_token", refresh_token);

// Data Source UI publishing description
HdpOAuthConnect.Publish = [
Beta = true,
Category = "Other",
ButtonText = { Extension.LoadString("ButtonTitle"), Extension.LoadString("ButtonHelp") },
LearnMoreUrl = "https://powerbi.microsoft.com/",
SourceImage = HdpOAuthConnect.Icons,
SourceTypeImage = HdpOAuthConnect.Icons
];

HdpOAuthConnect.Icons = [
Icon16 = { Extension.Contents("HdpOAuthConnect16.png"), Extension.Contents("HdpOAuthConnect20.png"), Extension.Contents("HdpOAuthConnect24.png"), Extension.Contents("HdpOAuthConnect32.png") },
Icon32 = { Extension.Contents("HdpOAuthConnect32.png"), Extension.Contents("HdpOAuthConnect40.png"), Extension.Contents("HdpOAuthConnect48.png"), Extension.Contents("HdpOAuthConnect64.png") }
];
