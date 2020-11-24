 

pragma solidity ^0.4.21;

 
contract CryptoEmojis {
     
    using SafeMath for uint256;    

     
    address dev;

     
    string constant private tokenName = "CryptoEmojis";
    string constant private tokenSymbol = "EMO";

     
    struct Emoji {
        string codepoints;
        string name;
        uint256 price;
        address owner;
        bool exists;
    }

    Emoji[] emojis;
    
     
    mapping(address => uint256) private balances;
    mapping(address => bytes16) private usernames;

     
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _id, uint256 _price);
    event PriceChange(uint256 indexed _id, uint256 _price);
    event UsernameChange(address indexed _owner, bytes16 _username);


    function CryptoEmojis() public {
        dev = msg.sender;
    }
    
    
    modifier onlyDev() {
        require(msg.sender == dev);
        _;
    }

   function name() public pure returns(string) {
       return tokenName;
   }

   function symbol() public pure returns(string) {
       return tokenSymbol;
   }

     
    function totalSupply() public view returns(uint256) {
        return emojis.length;
    }

     
   function balanceOf(address _owner) public view returns(uint256 balance) {
       return balances[_owner];
   }

     
    function usernameOf(address _owner) public view returns (bytes16) {
       return usernames[_owner];
    }
    
     
    function setUsername(bytes16 _username) public {
        usernames[msg.sender] = _username;
        emit UsernameChange(msg.sender, _username);
    }

     
    function ownerOf(uint256 _id) public constant returns (address) {
       return emojis[_id].owner;
    }
    
     
    function codepointsOf(uint256 _id) public view returns (string) {
       return emojis[_id].codepoints;
    }

     
    function nameOf(uint256 _id) public view returns (string) {
       return emojis[_id].name;
    }

     
    function priceOf(uint256 _id) public view returns (uint256 price) {
       return emojis[_id].price;
    }

     
    function create(string _codepoints, string _name, uint256 _price) public onlyDev() {
        Emoji memory _emoji = Emoji({
            codepoints: _codepoints,
            name: _name,
            price: _price,
            owner: dev,
            exists: true
        });
        emojis.push(_emoji);
        balances[dev]++;
    }

     
    function edit(uint256 _id, string _codepoints, string _name) public onlyDev() {
        require(emojis[_id].exists);
        emojis[_id].codepoints = _codepoints;
        emojis[_id].name = _name;
    }

     
    function buy(uint256 _id) payable public {
        require(emojis[_id].exists && emojis[_id].owner != msg.sender && msg.value >= emojis[_id].price);
        address oldOwner = emojis[_id].owner;
        uint256 oldPrice = emojis[_id].price;
        emojis[_id].owner = msg.sender;
        emojis[_id].price = oldPrice.div(100).mul(115);
        balances[oldOwner]--;
        balances[msg.sender]++;
        oldOwner.transfer(oldPrice.div(100).mul(96));
        if (msg.value > oldPrice) msg.sender.transfer(msg.value.sub(oldPrice));
        emit Transfer(oldOwner, msg.sender, _id, oldPrice);
        emit PriceChange(_id, emojis[_id].price);
    }

     
    function setPrice(uint256 _id, uint256 _price) public {
        require(emojis[_id].exists && emojis[_id].owner == msg.sender);
        emojis[_id].price =_price;
        emit PriceChange(_id, _price);
    }

     
    function withdraw() public onlyDev() {
        dev.transfer(address(this).balance);
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
}