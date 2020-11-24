 

pragma solidity ^0.4.24;

interface tokenRecipient {
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external;
}

contract braggerContract {

 
 
 

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    mapping (address => bool) private isUser;
    mapping (address => bool) private hasPicture;
    mapping (address => string) private userWalletToUserName;
    mapping (string => address) private userNameToUserWallet;
    mapping (string => string) private userNameToPicture;
    mapping (address => string) private userWalletToPicture;
    mapping (address => uint256) private fineLevel;

 
 
 

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Burn(address indexed from, uint256 value);

 
 
 

    address public ownerAddress = 0x000;
    address private bragAddress = 0x845EC9f9C0650b98f70E05fc259F4A04f6AC366e;

    string private initialQuote = "Teach your people with your wisdom.";
     
    string private initialPicture = "https://cdn2.iconfinder.com/data/icons/ios-7-icons/50/user_male2-512.png";

    uint256 basicFine = 25000000000000000;

    uint256 blocks;
    uint256 totalBraggedValue = 0;
    
    uint256 winningpot = 0;
    
    uint256 totalbrags = 0;

 
 
 

    struct Bragger{
        address braggerAddress;
        uint256 braggedAmount;
        string braggerQuote;
    }

    Bragger[] private braggers;

    struct User{
        address userAddress;
        string userName;
    }

    User[] private users;

 
 
 

     
    modifier onlyCreator() {
        require(msg.sender == ownerAddress);
        _;
    }


 
 
 

    constructor() public {
        blocks=0;
        ownerAddress = msg.sender;
    }

    function random() private view returns (uint8) {
        return uint8(uint256(keccak256(block.timestamp, block.difficulty))%251);
    }

    function random2() private view returns (uint8) {
        return uint8(uint256(keccak256(blocks, block.difficulty))%251);
    }

    function random3() private view returns (uint8) {
        return uint8(uint256(keccak256(blocks, block.difficulty))%braggers.length);
    }

 
 
 

    function getTotalBraggedVolume() public view returns (uint256 _amount){
        return totalBraggedValue;
    }

    function getCurrentBragKing() public view returns(address _bragger, uint256 _amount, string _quote, string _username, string _picture){
        _bragger = braggers[braggers.length-1].braggerAddress;
        _amount = braggers[braggers.length-1].braggedAmount;
        _quote = braggers[braggers.length-1].braggerQuote;
        if(isAlreadyUser(_bragger)){
            _username = getUserNameByWallet(_bragger);
        } else {
            _username = "";
        }

        if(hasPicture[_bragger]){
            _picture = userWalletToPicture[_bragger];
        } else {
            _picture = initialPicture;
        }

        return (_bragger, _amount, _quote, _username, _picture);
    }

    function arrayLength()public view returns(uint256 length){
        length = braggers.length;
        return length;
    }

    function getBraggerAtIndex(uint256 _index) public view returns(address _bragger, uint256 _brag, string _username, string _picture){
        _bragger = braggers[_index].braggerAddress;
        _brag = braggers[_index].braggedAmount;

        if(isAlreadyUser(_bragger)){
            _username = getUserNameByWallet(_bragger);
        } else {
            _username = "";
        }

         if(hasPicture[_bragger]){
            _picture = userWalletToPicture[_bragger];
        } else {
            _picture = initialPicture;
        }

        return (_bragger, _brag, _username, _picture);
    }

    function getUserNameByWallet(address _wallet) public view returns (string _username){
        require(isAlreadyUser(_wallet));
        _username = userWalletToUserName[_wallet];
        return _username;
    }

     function getUserPictureByWallet(address _wallet) public view returns (string _url){
        require(isAlreadyUser(_wallet));
        _url = userWalletToPicture[_wallet];
        return _url;
    }

    function getUserWalletByUsername(string _username) public view returns(address _address){
        address _user = userNameToUserWallet[_username];
        return (_user);
    }

    function getUserPictureByUsername(string _username) public view returns(string _url){
        _url = userNameToPicture[_username];
        return (_url);
    }

    function getFineLevelOfAddress(address _user) public view returns(uint256 _fineLevel, uint256 _fineAmount){
        _fineLevel = fineLevel[_user];
        _fineAmount = _fineLevel * basicFine;
        return (_fineLevel, _fineAmount);
    }

    function getFineLevelOfUsername(string _username) public view returns(uint256 _fineLevel, uint256 _fineAmount){
        address _user = userNameToUserWallet[_username];
        _fineLevel = fineLevel[_user];
        _fineAmount = _fineLevel * basicFine;
        return (_fineLevel, _fineAmount);
    }
    
    function getTotalBrags() public view returns(uint256){
        return totalbrags;
    }
    
    function getWinnerPot() public view returns(uint256){
        return winningpot;
    }

 
 
 

    function getCurrentPot() public view returns (uint256 _amount){
        return address(this).balance;
    }


    function brag() public payable{

        uint256 shortage = SafeMath.mul(30,SafeMath.div(msg.value, 100));

        if(braggers.length != 0){
         require(braggers[braggers.length-1].braggedAmount < msg.value);
        }

        Bragger memory _bragger = Bragger({
            braggerAddress: msg.sender,
            braggedAmount: msg.value,
            braggerQuote: initialQuote
        });

        braggers.push(_bragger);

        totalBraggedValue = totalBraggedValue + msg.value;
        
        winningpot = winningpot + SafeMath.sub(msg.value, shortage);

        bragAddress.transfer(shortage);

        if(random() == random2()){
            address sender = msg.sender;
            sender.transfer(SafeMath.mul(SafeMath.div(address(this).balance,100), 70));
            uint256 luckyIndex = random3();
            address luckyGuy = braggers[luckyIndex].braggerAddress;
            luckyGuy.transfer(address(this).balance);
        }

        blocks = SafeMath.add(blocks, random());
        totalbrags += 1;
    }

 
 
 

    function setTheKingsQuote(string _message) public payable{
        if(fineLevel[msg.sender] > 0){
            require(msg.value > (basicFine * fineLevel[msg.sender]));
        }
        address currentKing = braggers[braggers.length-1].braggerAddress;
        require(msg.sender == currentKing);
        braggers[braggers.length-1].braggerQuote = _message;
    }

 
 
 

    function isAlreadyUser(address _address) public view returns (bool status){
        if (isUser[_address]){
            return true;
        } else {
            return false;
        }
    }

    function hasProfilePicture(address _address) public view returns (bool status){
        if (isUser[_address]){
            return true;
        } else {
            return false;
        }
    }

    function createNewUser(string _username, string _pictureUrl) public {

        require(!isAlreadyUser(msg.sender));

        User memory _user = User({
            userAddress: msg.sender,
            userName: _username
        });

        userWalletToUserName[msg.sender] = _username;
        userNameToUserWallet[_username] = msg.sender;
        userNameToPicture[_username] = _pictureUrl;
        userWalletToPicture[msg.sender] = _pictureUrl;
        fineLevel[msg.sender] = 0;

        users.push(_user) - 1;
        isUser[msg.sender] = true;
        hasPicture[msg.sender] = true;
    }

 
 
 

    function resetQuote()public onlyCreator{
        braggers[braggers.length-1].braggerQuote = initialQuote;
        fineLevel[braggers[braggers.length-1].braggerAddress] = fineLevel[braggers[braggers.length-1].braggerAddress] + 1;
    }

    function resetUsername(string _username)public onlyCreator{
        address user = userNameToUserWallet[_username];
        userWalletToUserName[user] = "Mick";
        fineLevel[user] = fineLevel[user] + 1;
    }

    function resetUserPicture(string _username)public onlyCreator{
        address user = userNameToUserWallet[_username];
        userWalletToPicture[user] = initialPicture;
        fineLevel[user] = fineLevel[user] + 1;
    }

     

 
 
 

    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != 0x0);
         
        require(balanceOf[_from] >= _value);
         
        require(balanceOf[_to] + _value > balanceOf[_to]);
         
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
         
        balanceOf[_from] -= _value;
         
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
         
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);      
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    function reset()public onlyCreator {
        selfdestruct(ownerAddress);
    }

}

 
 
 

library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}