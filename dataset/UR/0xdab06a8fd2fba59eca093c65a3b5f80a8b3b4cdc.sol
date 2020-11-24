 

pragma solidity ^0.4.25;

library Math {

    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        assert(_b <= _a);
        return _a - _b;
    }

    function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
        c = _a + _b;
        assert(c >= _a);
        return c;
    }

}

contract VMToken {

    using Math for uint256;

    string public name = "Vehicle Mounted Mining";   
    string public symbol = "VM";  
    uint8  public decimals = 8;  
    uint256 public totalSupply = 5000000000 * 10 ** uint256(decimals);  
 
    mapping (address => uint256) public balanceOf;  
	address public owner;  
	
	bool public burnFinished = false;   
	uint256 public burnedSupply = 0;  
	uint256 public burnedLimit = 4800000000 * 10 ** uint256(decimals);  
	
	bool public mintingFinished = false;  

    constructor() public {
        balanceOf[msg.sender] = totalSupply;
		owner = msg.sender;
    }

	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}

	modifier canBurn() {
		require(!burnFinished);
		_;
	}
	
	modifier canMint() {
		require(!mintingFinished);
		_;
	}

	event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed burner, uint256 value);
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
	event Mint(address indexed to, uint256 amount);
    event MintFinished();

	function _transferOwnership(address _newOwner) internal {
		require(_newOwner != address(0));
		emit OwnershipTransferred(owner, _newOwner);
		owner = _newOwner;
	}
	
	 
	function transferOwnership(address _newOwner) public onlyOwner {
		_transferOwnership(_newOwner);
	}

    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0); 
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);

        uint previousBalances = balanceOf[_from] + balanceOf[_to];

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);

        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

     
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    function _burn(address _who, uint256 _value) internal {
        require(_value <= balanceOf[_who]);
        
        uint256 burnAmount = _value;

         
		if (burnAmount.add(burnedSupply) > burnedLimit){
			burnAmount = burnedLimit.sub(burnedSupply);
		}

        balanceOf[_who] = balanceOf[_who].sub(burnAmount);
        totalSupply = totalSupply.sub(burnAmount);
		burnedSupply = burnedSupply.add(burnAmount);
		
		 
		if (burnedSupply >= burnedLimit) {
			burnFinished = true;
		}
		
        emit Burn(_who, burnAmount);
        emit Transfer(_who, address(0), burnAmount);
    }

     
    function burn(uint256 _value) public onlyOwner canBurn {
        _burn(msg.sender, _value);
    }
	
	 
	function mint(address _to, uint256 _amount) public onlyOwner canMint returns (bool){
		totalSupply = totalSupply.add(_amount);
		balanceOf[_to] = balanceOf[_to].add(_amount);
		emit Mint(_to, _amount);
		emit Transfer(address(0), _to, _amount);
		return true;
	}
	
	 
	function finishMinting() onlyOwner canMint public returns (bool) {
		mintingFinished = true;
		emit MintFinished();
		return true;
	}

}