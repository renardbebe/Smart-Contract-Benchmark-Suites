 

pragma solidity ^0.4.16;

contract AbstractENS {
    function owner(bytes32 node) public constant returns(address);
}
contract ReverseRegistrar {
    function claim(address owner) public returns (bytes32);
}

contract owned {
    address public owner;
    address public admin;

    function rens() internal {
	AbstractENS ens = AbstractENS(0x314159265dD8dbb310642f98f50C066173C1259b);  
	ReverseRegistrar registrar = ReverseRegistrar(ens.owner(0x91d1777781884d03a6757a803996e38de2a42967fb37eeaca72729271025a9e2));  
	if(address(registrar) != 0)
	    registrar.claim(owner);
    }

    function owned() public {
        owner = msg.sender;
        admin = msg.sender;
        rens();
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyAdmin {
        require(msg.sender == admin || msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
        rens();
    }

    function setAdmin(address newAdmin) onlyOwner public {
        admin = newAdmin;
    }
}

contract RichiumToken is owned {
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping (address => uint256) public balanceOf;

    mapping (address => bool) public approvedAccount;
    
    event ApprovedAccount(address target, bool approve);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    
    uint256 public bid;
    uint256 public ask;

    function RichiumToken(uint256 initialSupply, string tokenName, string tokenSymbol) public {
        totalSupply = initialSupply * (10 ** uint256(decimals));
        balanceOf[msg.sender] = totalSupply;
        name = tokenName;
        symbol = tokenSymbol;

	approvedAccount[msg.sender] = true;
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        require(approvedAccount[_from]);
        require(approvedAccount[_to]);

        uint256 previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

     
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

     
     
     
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        emit Transfer(0, this, mintedAmount);
        emit Transfer(this, target, mintedAmount);
    }

     
    function burnFrom(address _from, uint256 _value) onlyOwner public {
        require(balanceOf[_from] >= _value);
        balanceOf[_from] -= _value;
        totalSupply -= _value;
        emit Burn(_from, _value);
    }

     
     
    function withdraw(uint256 amount) onlyOwner public {
        require(address(this).balance >= amount);
        owner.transfer(amount);
    }

     
     
     
    function approveAccount(address target, bool approve) onlyAdmin public {
        approvedAccount[target] = approve;
        emit ApprovedAccount(target, approve);
    }

     
     
    function setPrices(uint256 newBid, uint256 newAsk) onlyAdmin public {
        bid = newBid;
        ask = newAsk;
    }

     
    function () payable public {
        buy();
    }
    
     
    function buy() payable public {
        require(ask > 0);
        uint256 r = msg.value * (10 ** uint256(decimals));
        require(r > msg.value);
        _transfer(this, msg.sender, r / ask);
    }

     
     
    function sell(uint256 amount) public {
        require(bid > 0);
        require(amount * bid >= amount);
        uint256 e = (amount * bid) / (10 ** uint256(decimals));
        require(address(this).balance >= e);
        _transfer(msg.sender, this, amount);
        msg.sender.transfer(e);					 
    }
}