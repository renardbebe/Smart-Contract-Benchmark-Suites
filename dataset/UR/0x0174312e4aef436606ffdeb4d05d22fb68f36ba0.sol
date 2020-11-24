 

pragma solidity ^0.4.13;

contract Latium {
    string public constant name = "Latium";
    string public constant symbol = "LAT";
    uint8 public constant decimals = 16;
    uint256 public constant totalSupply =
        30000000 * 10 ** uint256(decimals);

     
    address public owner;

     
    mapping (address => uint256) public balanceOf;

     
    event Transfer(address indexed _from, address indexed _to, uint _value);

     
    function Latium() {
        owner = msg.sender;
        balanceOf[owner] = totalSupply;
    }

     
    function transfer(address _to, uint256 _value) {
         
        require(_to != 0x0);
         
        require(msg.sender != _to);
         
        require(_value > 0 && balanceOf[msg.sender] >= _value);
         
        require(balanceOf[_to] + _value > balanceOf[_to]);
         
        balanceOf[msg.sender] -= _value;
         
        balanceOf[_to] += _value;
         
        Transfer(msg.sender, _to, _value);
    }
}

contract LatiumSeller {
    address private constant _latiumAddress = 0xBb31037f997553BEc50510a635d231A35F8EC640;
    Latium private constant _latium = Latium(_latiumAddress);

     
    uint256 private _etherAmount = 0;

     
    uint256 private constant _tokenPrice = 10 finney;  
    uint256 private _minimumPurchase =
        10 * 10 ** uint256(_latium.decimals());  

     
    address public owner;

     
    function LatiumSeller() {
        owner = msg.sender;
    }

    function tokenPrice() constant returns(uint256 tokenPrice) {
        return _tokenPrice;
    }

    function minimumPurchase() constant returns(uint256 minimumPurchase) {
        return _minimumPurchase;
    }

     
    function _tokensToSell() private returns (uint256 tokensToSell) {
        return _latium.balanceOf(address(this));
    }

     
     
    function () payable {
         
        require(msg.sender != owner && msg.sender != address(this));
         
        uint256 tokensToSell = _tokensToSell();
        require(tokensToSell > 0);
         
         
         
         
        uint256 tokensToBuy =
            msg.value * 10 ** uint256(_latium.decimals()) / _tokenPrice;
         
        require(tokensToBuy >= _minimumPurchase);
         
        require(tokensToBuy <= tokensToSell);
        _etherAmount += msg.value;
        _latium.transfer(msg.sender, tokensToBuy);
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function withdrawEther(uint256 _amount) onlyOwner {
        if (_amount == 0) {
             
            _amount = _etherAmount;
        }
        require(_amount > 0 && _etherAmount >= _amount);
        _etherAmount -= _amount;
        msg.sender.transfer(_amount);
    }

     
    function withdrawLatium(uint256 _amount) onlyOwner {
        uint256 availableLatium = _tokensToSell();
        require(availableLatium > 0);
        if (_amount == 0) {
             
            _amount = availableLatium;
        }
        require(availableLatium >= _amount);
        _latium.transfer(msg.sender, _amount);
    }
}