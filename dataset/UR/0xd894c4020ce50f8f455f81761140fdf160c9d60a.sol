 

pragma solidity ^0.4.23;
 
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


 
contract Ownable {
    address public owner;

    event onOwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    function Ownable() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit onOwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

 
contract Lockable is Ownable {
    event onLock();

    bool public locked = false;
     
    modifier whenNotLocked() {
        require(!locked);
        _;
    }

     
    function setLock(bool _value) onlyOwner public {
        locked = _value;
        emit onLock();
    }
}

 
contract ERC20Basic {
    function totalSupply() public view returns (uint256);

    function actualCap() public view returns (uint256);

    function balanceOf(address who) public view returns (uint256);

    function transfer(address to, uint256 value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);

    function transferFrom(address from, address to, uint256 value) public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract BasicToken is ERC20Basic, Lockable {
    using SafeMath for uint256;

    uint8 public constant decimals = 18;  
    mapping(address => uint256) balances;
    uint256 totalSupply_;
    uint256 actualCap_;

     
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

     
    function actualCap() public view returns (uint256) {
        return actualCap_;
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(!locked || msg.sender == owner);
         
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

}


 
contract StandardToken is ERC20, BasicToken {

    mapping(address => mapping(address => uint256)) internal allowed;

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(!locked || msg.sender == owner);
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        require(!locked || msg.sender == owner);
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        require(!locked || msg.sender == owner);
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        require(!locked || msg.sender == owner);
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}

 
contract MintableToken is StandardToken {
    event onMint(address indexed to, uint256 amount);
    event onSetMintable();

    bool public mintable = true;

    modifier canMint() {
        require(mintable);
        _;
    }

     
    function mint(address _to, uint256 _amount) onlyOwner whenNotLocked canMint public returns (bool) {
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit onMint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

     
    function setMintable(bool _value) onlyOwner public returns (bool) {
        mintable = _value;
        emit onSetMintable();
        return true;
    }
}

 
contract BurnableToken is StandardToken {
    event onBurn(address indexed burner, uint256 value);

     
    function burn(uint256 _value) whenNotLocked public returns (bool)  {
        require(_value <= balances[msg.sender]);
         
         

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        actualCap_ = actualCap_.sub(_value);
        emit onBurn(burner, _value);
        emit Transfer(burner, address(0), _value);
        return true;
    }
}

 
contract DropableToken is MintableToken {
    event onSetDropable();
    event onSetDropAmount();

    bool public dropable = false;
    uint256 dropAmount_ = 100000 * (10 ** uint256(decimals));  

     
    modifier whenDropable() {
        require(dropable);
        _;
    }
     
    function setDropable(bool _value) onlyOwner public {
        dropable = _value;
        emit onSetDropable();
    }

     
    function setDropAmount(uint256 _value) onlyOwner public {
        dropAmount_ = _value;
        emit onSetDropAmount();
    }

     
    function getDropAmount() public view returns (uint256) {
        return dropAmount_;
    }

     
    function airdropWithAmount(address [] _recipients, uint256 _value) onlyOwner canMint whenDropable external {
        for (uint i = 0; i < _recipients.length; i++) {
            address recipient = _recipients[i];
            require(totalSupply_.add(_value) <= actualCap_);
            mint(recipient, _value);
        }
    }

    function airdrop(address [] _recipients) onlyOwner canMint whenDropable external {
        for (uint i = 0; i < _recipients.length; i++) {
            address recipient = _recipients[i];
            require(totalSupply_.add(dropAmount_) <= actualCap_);
            mint(recipient, dropAmount_);
        }
    }

     
     
    function getAirdrop() whenNotLocked canMint whenDropable external returns (bool) {
        require(totalSupply_.add(dropAmount_) <= actualCap_);
        mint(msg.sender, dropAmount_);
        return true;
    }
}


 
contract PurchasableToken is StandardToken {
    event onPurchase(address indexed to, uint256 etherAmount, uint256 tokenAmount);
    event onSetPurchasable();
    event onSetTokenPrice();
    event onWithdraw(address to, uint256 amount);

    bool public purchasable = true;
    uint256 tokenPrice_ = 0.0000000001 ether;
    uint256 etherAmount_;

    modifier canPurchase() {
        require(purchasable);
        _;
    }

     
    function purchase() whenNotLocked canPurchase public payable returns (bool) {
        uint256 ethAmount = msg.value;
        uint256 tokenAmount = ethAmount.div(tokenPrice_).mul(10 ** uint256(decimals));
        require(totalSupply_.add(tokenAmount) <= actualCap_);
        totalSupply_ = totalSupply_.add(tokenAmount);
        balances[msg.sender] = balances[msg.sender].add(tokenAmount);
        etherAmount_ = etherAmount_.add(ethAmount);
        emit onPurchase(msg.sender, ethAmount, tokenAmount);
        emit Transfer(address(0), msg.sender, tokenAmount);
        return true;
    }

     
    function setPurchasable(bool _value) onlyOwner public returns (bool) {
        purchasable = _value;
        emit onSetPurchasable();
        return true;
    }

     
    function setTokenPrice(uint256 _value) onlyOwner public {
        tokenPrice_ = _value;
        emit onSetTokenPrice();
    }

     
    function getTokenPrice() public view returns (uint256) {
        return tokenPrice_;
    }

     
    function withdraw(uint256 _amountOfEthers) onlyOwner public returns (bool){
        address ownerAddress = msg.sender;
        require(etherAmount_>=_amountOfEthers);
        ownerAddress.transfer(_amountOfEthers);
        etherAmount_ = etherAmount_.sub(_amountOfEthers);
        emit onWithdraw(ownerAddress, _amountOfEthers);
        return true;
    }
}

contract RBTToken is DropableToken, BurnableToken, PurchasableToken {
    string public name = "RBT - a flexible token which can be rebranded";
    string public symbol = "RBT";
    string public version = '1.0';
    string public desc = "";
    uint256 constant CAP = 100000000000 * (10 ** uint256(decimals));  
    uint256 constant STARTUP = 100000000 * (10 ** uint256(decimals));  

     
    function RBTToken() public {
        mint(msg.sender, STARTUP);
        actualCap_ = CAP;
    }

     
     
     
    function() public payable {
        revert();
    }

     
    function setName(string _name) onlyOwner public {
        name = _name;
    }

     
    function setSymbol(string _symbol) onlyOwner public {
        symbol = _symbol;
    }

     
    function setVersion(string _version) onlyOwner public {
        version = _version;
    }

     
    function setDesc(string _desc) onlyOwner public {
        desc = _desc;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        if (approve(_spender, _value)) {
             
             
             
            if (!_spender.call(bytes4(bytes32(keccak256("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) {revert();}
            return true;
        }
    }

     
    function approveAndCallcode(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        if (approve(_spender, _value)) {
             
            if (!_spender.call(_extraData)) {revert();}
            return true;
        }
    }

}