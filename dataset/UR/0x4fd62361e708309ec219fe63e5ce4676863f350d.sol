 

pragma solidity ^0.4.24;


 

contract Owned {
    address private _owner;
    address private _newOwner;

    event TransferredOwner(
        address indexed previousOwner,
        address indexed newOwner
    );

	 
    constructor() internal {
        _owner = msg.sender;
        emit TransferredOwner(address(0), _owner);
    }

	 

    function owner() public view returns(address) {
        return _owner;
    }

   
    modifier onlyOwner() {
        require(isOwner(), "Access is denied");
        _;
    }

   
    function isOwner() public view returns(bool) {
        return msg.sender == _owner;
    }

   
    function renounceOwner() public onlyOwner {
        emit TransferredOwner(_owner, address(0));
        _owner = address(0);
    }

   
    function transferOwner(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Empty address");
        _newOwner = newOwner;
    }


    function cancelOwner() public onlyOwner {
        _newOwner = address(0);
    }

    function confirmOwner() public {
        require(msg.sender == _newOwner, "Access is denied");
        emit TransferredOwner(_owner, _newOwner);
        _owner = _newOwner;
    }
}


 

contract ERC20CoreBase {

     
     
     


    mapping (address => uint) internal _balanceOf;
    uint internal _totalSupply; 

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );


     

    function totalSupply() public view returns(uint) {
        return _totalSupply;
    }

     

    function balanceOf(address owner) public view returns(uint) {
        return _balanceOf[owner];
    }



     

    function _transfer(address from, address to, uint256 value) internal {
        _checkRequireERC20(to, value, true, _balanceOf[from]);

        _balanceOf[from] -= value;
        _balanceOf[to] += value;
        emit Transfer(from, to, value);
    }


     

    function _mint(address account, uint256 value) internal {
        _checkRequireERC20(account, value, false, 0);
        _totalSupply += value;
        _balanceOf[account] += value;
        emit Transfer(address(0), account, value);
    }

     

    function _burn(address account, uint256 value) internal {
        _checkRequireERC20(account, value, true, _balanceOf[account]);

        _totalSupply -= value;
        _balanceOf[account] -= value;
        emit Transfer(account, address(0), value);
    }


    function _checkRequireERC20(address addr, uint value, bool checkMax, uint max) internal pure {
        require(addr != address(0), "Empty address");
        require(value > 0, "Empty value");
        if (checkMax) {
            require(value <= max, "Out of value");
        }
    }

}


contract ERC20Core is ERC20CoreBase {
     

    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }
}


contract ERC20WithApproveBase is ERC20CoreBase {
    mapping (address => mapping (address => uint256)) private _allowed;


    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    ); 

     
    
    function allowance(address owner, address spender) public view returns(uint) {
        return _allowed[owner][spender];
    }

     

    function _approve(address spender, uint256 value) internal {
        _checkRequireERC20(spender, value, true, _balanceOf[msg.sender]);

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
    }

     

    function _transferFrom(address from, address to, uint256 value) internal {
        _checkRequireERC20(to, value, true, _allowed[from][msg.sender]);

        _allowed[from][msg.sender] -= value;
        _transfer(from, to, value);
    }

     

    function _increaseAllowance(address spender, uint256 value)  internal {
        _checkRequireERC20(spender, value, false, 0);
        require(_balanceOf[msg.sender] >= (_allowed[msg.sender][spender] + value), "Out of value");

        _allowed[msg.sender][spender] += value;
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    }



     

    function _decreaseAllowance(address spender, uint256 value) internal {
        _checkRequireERC20(spender, value, true, _allowed[msg.sender][spender]);

        _allowed[msg.sender][spender] -= value;
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    }

}


contract ERC20WithApprove is ERC20WithApproveBase {
     

    function approve(address spender, uint256 value) public {
        _approve(spender, value);
    }

     

    function transferFrom(address from, address to, uint256 value) public {
        _transferFrom(from, to, value);
    }

     

    function increaseAllowance(address spender, uint256 value)  public {
        _increaseAllowance(spender, value);
    }



     

    function decreaseAllowance(address spender, uint256 value) public {
        _decreaseAllowance(spender, value);
    }
}


contract VendiCoins is ERC20WithApprove, Owned {
	string public name;
	string public symbol;
	uint public decimals;
	bool public frozen;


	 
	event Freeze ();
	event Unfreeze ();


    modifier onlyUnfreeze() {
        require(!frozen, "Action temporarily paused");
        _;
    }



	constructor(string _name, string _symbol, uint _decimals, uint total, bool _frozen) public {
		name = _name;
		symbol = _symbol;
		decimals = _decimals;
		frozen = _frozen;

		_mint(msg.sender, total);
	} 

	function mint(address account, uint value) public onlyOwner {
		_mint(account, value);
	}

	function burn(uint value) public {
		_burn(msg.sender, value);
	} 


	function transfer(address to, uint value) public onlyUnfreeze {
		_transfer(msg.sender, to, value);
	}

	function transferFrom(address from, address to, uint value) public onlyUnfreeze {
		_transferFrom(from, to, value);
	}


	function freezeTransfers () public onlyOwner {
		if (!frozen) {
			frozen = true;
			emit Freeze();
		}
	}

	 
	function unfreezeTransfers () public onlyOwner {
		if (frozen) {
			frozen = false;
			emit Unfreeze();
		}
	}
}