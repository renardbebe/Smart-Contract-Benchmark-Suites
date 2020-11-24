 

pragma solidity ^0.4.24;
 
 
contract Erc20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}
 
 
library LibSafeMath {
     
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
 
     
    function mulDiv(uint256 a, uint256 b, uint256 c) internal pure returns (uint256) {
        uint256 d = mul(a, b);
        return div(d, c);
    }
}
 
 
contract OwnedToken {
    using LibSafeMath for uint256;
   
     
    string public name = 'Altty';
    string public symbol = 'LTT';
    uint8 public decimals = 18;
     
    mapping (address => mapping (address => uint256)) private allowed;
     
    mapping(address => uint256) private shares;
     
    uint256 private shareCount_;
     
    address public owner = msg.sender;
     
    mapping(address => bool) public isAdmin;
     
    mapping(address => bool) public holded;
 
     
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed owner, uint256 amount);
    event Mint(address indexed to, uint256 amount);
 
     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
     
    modifier onlyAdmin() {
        require(isAdmin[msg.sender]);
        _;
    }
 
     
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));  
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
     
    function empowerAdmin(address _user) onlyOwner public {
        isAdmin[_user] = true;
    }
    function fireAdmin(address _user) onlyOwner public {
        isAdmin[_user] = false;
    }
     
    function hold(address _user) onlyOwner public {
        holded[_user] = true;
    }
     
    function unhold(address _user) onlyOwner public {
        holded[_user] = false;
    }
   
     
    function setName(string _name)  onlyOwner public {
        name = _name;
    }
    function setSymbol(string _symbol)  onlyOwner public {
        symbol = _symbol;
    }
    function setDecimals(uint8 _decimals)  onlyOwner public {
        decimals = _decimals;
    }
 
     
    function totalSupply() public view returns (uint256) {
        return shareCount_;
    }
 
     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return shares[_owner];
    }
 
     
    function shareTransfer(address _from, address _to, uint256 _value) internal returns (bool) {
        require(!holded[_from]);
        if(_from == address(0)) {
            emit Mint(_to, _value);
            shareCount_ =shareCount_.add(_value);
        } else {
            require(_value <= shares[_from]);
            shares[_from] = shares[_from].sub(_value);
        }
        if(_to == address(0)) {
            emit Burn(msg.sender, _value);
            shareCount_ =shareCount_.sub(_value);
        } else {
            shares[_to] =shares[_to].add(_value);
        }
        emit Transfer(_from, _to, _value);
        return true;
    }
 
     
    function transfer(address _to, uint256 _value) public returns (bool) {
        return shareTransfer(msg.sender, _to, _value);
    }
 
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_value <= allowed[_from][msg.sender]);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        return shareTransfer(_from, _to, _value);
    }
 
     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
 
     
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }
 
     
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
 
     
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
   
     
    function withdraw(address _to, uint256 _value) onlyOwner public returns (bool) {
        require(_to != address(0));
        require(_value <= address(this).balance);
        _to.transfer(_value);
        return true;
    }
   
     
    function withdrawToken(address token, address _to, uint256 amount) onlyOwner public returns (bool) {
        require(token != address(0));
        require(Erc20Basic(token).balanceOf(address(this)) >= amount);
        bool transferOk = Erc20Basic(token).transfer(_to, amount);
        require(transferOk);
        return true;
    }
}
 
contract TenderToken is OwnedToken {
     
    uint256 public price = 3 ether / 1000000;
    uint256 public sellComission = 2900;  
    uint256 public buyComission = 2900;  
   
     
    uint256 public priceUnits = 1 ether;
    uint256 public sellComissionUnits = 100000;
    uint256 public buyComissionUnits = 100000;
   
     
    struct SellOrder {
        address user;
        uint256 shareNumber;
    }
    struct BuyOrder {
        address user;
        uint256 amountWei;
    }
   
     
    SellOrder[] public sellOrder;
    BuyOrder[] public buyOrder;
    uint256 public sellOrderTotal;
    uint256 public buyOrderTotal;
   
 
     
    function() public payable {
        if(!isAdmin[msg.sender]) {
            buyOrder.push(BuyOrder(msg.sender, msg.value));
            buyOrderTotal += msg.value;
        }
    }
 
     
    function shareTransfer(address _from, address _to, uint256 _value) internal returns (bool) {
        if(_to == address(this)) {
            sellOrder.push(SellOrder(msg.sender, _value));
            sellOrderTotal += _value;
        }
        return super.shareTransfer(_from, _to, _value);
    }
 
     
    function setPrice(uint256 _price) onlyAdmin public {
        price = _price;
    }
    function setSellComission(uint _sellComission) onlyOwner public {
        sellComission = _sellComission;
    }
    function setBuyComission(uint _buyComission) onlyOwner public {
        buyComission = _buyComission;
    }
    function setPriceUnits(uint256 _priceUnits) onlyOwner public {
        priceUnits = _priceUnits;
    }
    function setSellComissionUnits(uint _sellComissionUnits) onlyOwner public {
        sellComissionUnits = _sellComissionUnits;
    }
    function setBuyComissionUnits(uint _buyComissionUnits) onlyOwner public {
        buyComissionUnits = _buyComissionUnits;
    }
   
     
    function shareToWei(uint256 shareNumber) public view returns (uint256) {
        uint256 amountWei = shareNumber.mulDiv(price, priceUnits);
        uint256 comissionWei = amountWei.mulDiv(sellComission, sellComissionUnits);
        return amountWei.sub(comissionWei);
    }
 
     
    function weiToShare(uint256 amountWei) public view returns (uint256) {
        uint256 shareNumber = amountWei.mulDiv(priceUnits, price);
        uint256 comissionShare = shareNumber.mulDiv(buyComission, buyComissionUnits);
        return shareNumber.sub(comissionShare);
    }
   
     
    function confirmAllBuys() external onlyAdmin {
        while(buyOrder.length > 0) {
            _confirmOneBuy();
        }
    }
    function confirmAllSells() external onlyAdmin {
        while(sellOrder.length > 0) {
            _confirmOneSell();
        }
    }
   
     
    function confirmOneBuy() external onlyAdmin {
        if(buyOrder.length > 0) {
            _confirmOneBuy();
        }
    }
    function confirmOneSell() external onlyAdmin {
        _confirmOneSell();
    }
     
    function cancelOneSell() internal {
        uint256 i = sellOrder.length-1;
        shareTransfer(address(this), sellOrder[i].user, sellOrder[i].shareNumber);
        sellOrderTotal -= sellOrder[i].shareNumber;
        delete sellOrder[sellOrder.length-1];
        sellOrder.length--;
    }
   
     
    function _confirmOneBuy() internal {
        uint256 i = buyOrder.length-1;
        uint256 amountWei = buyOrder[i].amountWei;
        uint256 shareNumber = weiToShare(amountWei);
        address user = buyOrder[i].user;
        shareTransfer(address(0), user, shareNumber);
        buyOrderTotal -= amountWei;
        delete buyOrder[buyOrder.length-1];
        buyOrder.length--;
    }
    function _confirmOneSell() internal {
        uint256 i = sellOrder.length-1;
        uint256 shareNumber = sellOrder[i].shareNumber;
        uint256 amountWei = shareToWei(shareNumber);
        address user = sellOrder[i].user;
        shareTransfer(address(this), address(0), shareNumber);
        sellOrderTotal -= shareNumber;
        user.transfer(amountWei);
        delete sellOrder[sellOrder.length-1];
        sellOrder.length--;
    }
}