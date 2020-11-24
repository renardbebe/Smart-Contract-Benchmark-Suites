 

pragma solidity ^0.4.21;


 
 
 
 


 
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address _who) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
}


 
contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed _previousOwner, address indexed _newOwner);


     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

     
    function rescueTokens(ERC20Basic _token) external onlyOwner {
        uint256 balance = _token.balanceOf(this);
        assert(_token.transfer(owner, balance));
    }

     
    function withdrawEther() external onlyOwner {
        owner.transfer(address(this).balance);
    }
}


 
library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        return a / b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
}


 
contract SellTokens is Ownable {
    using SafeMath for uint256;

    ERC20Basic public token;

    uint256 decimalDiff;
    uint256 public rate;
    string public description;
    string public telegram;


     
    constructor(ERC20Basic _token, uint256 _tokenDecimals, uint256 _rate, string _description, string _telegram) public {
        uint256 etherDecimals = 18;

        token = _token;
        decimalDiff = etherDecimals.sub(_tokenDecimals);
        rate = _rate;
        description = _description;
        telegram = _telegram;
    }

     
    function () public payable {
        uint256 weiAmount = msg.value;
        uint256 tokenAmount = weiAmount.mul(rate).div(10 ** decimalDiff);
        
        require(tokenAmount > 0);
        
        assert(token.transfer(msg.sender, tokenAmount));
        owner.transfer(address(this).balance);
    }

     
    function setRate(uint256 _rate) external onlyOwner returns (bool) {
        rate = _rate;
        return true;
    }

     
    function setDescription(string _description) external onlyOwner returns (bool) {
        description = _description;
        return true;
    }

     
    function setTelegram(string _telegram) external onlyOwner returns (bool) {
        telegram = _telegram;
        return true;
    }
}