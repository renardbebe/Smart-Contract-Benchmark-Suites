 

pragma solidity ^0.5.8;
 

contract Erc20Token {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
 }


contract Base {
    address public owner;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function setOwner(address _newOwner)  external  onlyOwner {
        require(_newOwner != address(0x0));
        owner = _newOwner;
    }

    uint public currentEventId = 1;

    function getEventId() internal returns(uint _result) {
        _result = currentEventId;
        currentEventId ++;
    }

}

contract Myosotis is Base {

    constructor(address _owner)  public {
        require(_owner != address(0x0));
        owner = _owner;
    }

    mapping(address => bool) public Admins;

    function addAdmin(address _admin) external onlyOwner{
        require(_admin != address(0x0));
        Admins[_admin] = true;
    }

    function delAdmin(address _admin) external onlyOwner{
        require(_admin != address(0x0));
        Admins[_admin] = false;
    }

    modifier onlyAdmin {
        require(Admins[msg.sender] == true);
        _;
    }

    function getProgramName() external view returns(string memory _result)
    {
        _result = ownerKeyValue[1];
    }

    function getProgramVersion() external view returns(string  memory _result)
    {
        _result = ownerKeyValue[2];
    }

    function getProgramIntroduction() external view returns(string memory  _result)
    {
        _result = ownerKeyValue[3];
    }

    function getProgramBittorrent() external view returns(string  memory _result)
    {
        _result = ownerKeyValue[4];
    }

    function getProgrameMule() external view returns(string  memory _result)
    {
        _result = ownerKeyValue[5];
    }

    function getProgramAuthor() external view returns(string  memory _result)
    {
        _result = ownerKeyValue[6];
    }

    function getProgramTelegram() external view returns(string  memory _result)
    {
        _result = ownerKeyValue[7];
    }

    function getProgramBBS() external view returns(string  memory _result)
    {
        _result = ownerKeyValue[8];
    }

    function getProgramTorWebSite() external view returns(string  memory _result)
    {
        _result = ownerKeyValue[9];
    }

    function getProgramWebSite() external view returns(string  memory _result)
    {
        _result = ownerKeyValue[10];
    }

    mapping(uint256 => string) public ownerKeyValue;

    event OnSaveOwnerKeyValue(uint256 indexed _key, string  _value, string _remark, address _owner, uint _eventId);
    
    function saveOwnerKeyValue(uint256 _key, string calldata  _value, string calldata _remark) external onlyOwner {           
        require(_key > 0);
        ownerKeyValue[_key] = _value;
        emit OnSaveOwnerKeyValue(_key, _value, _remark, msg.sender, getEventId());
    }

    mapping(uint256 => string) public adminKeyValue;

    event OnSaveAdminKeyValue(address indexed _admin, uint256 indexed _key, string   _value, string _remark, uint _eventId);

    function saveAdminKeyValue(uint256 _key, string   calldata  _value, string calldata _remark) external onlyAdmin {           
        require(_key > 0);
        adminKeyValue[_key] = _value;
        emit OnSaveAdminKeyValue(msg.sender, _key, _value, _remark, getEventId());
    }

    mapping(address => mapping(uint256 => string)) public userKeyValue;

    event OnSaveUserKeyValue(address indexed _user, uint256 indexed _key, string  _value, string _remark, uint _eventId);

    function saveUserKeyValue(uint256 _key, string calldata _value, string calldata _remark) external {                      
        require(_key > 0);
        userKeyValue[msg.sender][_key] = _value;
        emit OnSaveUserKeyValue(msg.sender, _key, _value, _remark, getEventId());
    }

    event OnPublishKeyValue1(address indexed _user, uint256 indexed _key, string   _value, string _remark, uint _eventId); 

    function publishKeyValue1(uint256 _key, string  calldata   _value, string calldata _remark) external {                  
        emit OnPublishKeyValue1(msg.sender, _key, _value, _remark, getEventId());
    }
   
    event OnPublishKeyValue2(address indexed _user, string indexed _key, string   _value, string _remark, uint _eventId); 

    function publishKeyValue2(string calldata  _key, string  calldata  _value, string calldata _remark) external {                  
        emit OnPublishKeyValue2(msg.sender, _key, _value, _remark, getEventId());
    }
   
    enum LanguageEnum { English, Chinese, French, Portuguese, Spanish, Japanese, German, Korean, Russian, Hindi, Javanese, Vietnamese, Arabic, Turkish, Urdu, Polish, Ukrainian, Italian, Others }
    
    event OnPublishMediaInfo1(LanguageEnum indexed _language, address indexed _user, string _title, string _BTLink, string _eMuleLink, uint _eventId);
    event OnPublishMediaInfo2(string _tag1, string _tag2, string _tag3, string _remark, uint _eventId);
   
    function publishMediaInfo(LanguageEnum _language, string memory _title, string memory _BTLink, string memory _eMuleLink, 
        string memory _tag1, string memory _tag2, string memory _tag3, string memory _remark) public 
    {
        uint eid = getEventId();
        emit OnPublishMediaInfo1(_language, msg.sender, _title, _BTLink, _eMuleLink, eid);
        emit OnPublishMediaInfo2(_tag1, _tag2, _tag3, _remark, eid);
    }

    event OnPublishBtMagnet(LanguageEnum indexed _language, address indexed _publisher, bytes32 _title, bytes20 _magnet, bytes32 _tag1, bytes32 _tag2, bytes32 _tag3,  uint _eventId);

    function publishBtMagnet1(LanguageEnum _language, bytes32 _title, bytes20 _magnet, bytes32 _tag1, bytes32 _tag2, bytes32 _tag3) external 
    {
        uint eid = getEventId();
        emit OnPublishBtMagnet(_language, msg.sender, _title, _magnet,  _tag1, _tag2, _tag3,  eid);
    }

    function publishBtMagnet2(LanguageEnum _language, bytes32[]  calldata _titles, bytes20[] calldata _magnets, bytes32[]  calldata _tag1s, bytes32[]  calldata _tag2s, bytes32[] calldata  _tag3s) external 
    {
        require(_magnets.length == _titles.length);

        for(uint i = 0; i < _titles.length; i++){
            uint eid = getEventId();
            emit OnPublishBtMagnet(_language, msg.sender, _titles[i], _magnets[i],  _tag1s[i], _tag2s[i], _tag3s[i],  eid);
        }
    }

    function publishBtMagnet3(LanguageEnum[] calldata  _languages, bytes32[]  calldata _titles, bytes20[] calldata _magnets , bytes32[] calldata _tag1s, bytes32[]  calldata _tag2s, bytes32[]  calldata _tag3s) external 
    {
        require(_languages.length == _titles.length);
        require(_languages.length == _magnets.length);

        for(uint i = 0; i < _languages.length; i++){
            uint eid = getEventId();
            emit OnPublishBtMagnet(_languages[i], msg.sender, _titles[i], _magnets[i],  _tag1s[i], _tag2s[i], _tag3s[i],  eid);
        }
    }

    event OnRegisterDapp(address _user, LanguageEnum _defaultLanguage, bytes32 _name, string _introduction, bytes32 _author, bytes32 _tag1, bytes32 _tag2, bytes32 _tag3, bytes20 _magnet, address _contractAddress,  uint _eventId);

    function registerDapp(LanguageEnum _defaultLanguage, bytes32 _name, string calldata _introduction, bytes32 _author, bytes32 _tag1, bytes32 _tag2, bytes32 _tag3, bytes20 _magnet, address _contractAddress) external onlyOwner
    {
        uint eid = getEventId();
        emit OnRegisterDapp(msg.sender, _defaultLanguage, _name,  _introduction,  _author,  _tag1,  _tag2,  _tag3,  _magnet, _contractAddress,  eid);
    }
    
    function () external payable {
         
    }
    

    function disToken(address _token) external onlyOwner {
        if (_token != address(0x0)){
            Erc20Token token = Erc20Token(_token);
            uint amount = token.balanceOf(address(this));
            if (amount > 0) {
                token.transfer(msg.sender, amount);
            }
        }
        else{
            msg.sender.transfer(address(this).balance);
        }
    }


}