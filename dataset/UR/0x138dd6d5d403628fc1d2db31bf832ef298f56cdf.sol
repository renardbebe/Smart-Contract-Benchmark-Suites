 

pragma solidity ^0.5.6;

 library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

     
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

     
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
         
        require(b > 0, errorMessage);
        uint256 c = a / b;
         

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

     
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

 
 
contract Context {
     
     
    constructor () internal { }
     

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;  
        return msg.data;
    }
}

 
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

     
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


contract Yoinkable {
    constructor() public {
        selfdestruct(msg.sender);
    }
}

contract ERC20Interface {
    function transferFrom(address src, address dst, uint wad) public returns (bool);
    function transfer(address dst, uint wad) public returns (bool);
    function approve(address guy, uint wad) public returns (bool);
}

contract UniswapInterface {
    function tokenToEthTransferInput(uint256 tokens_sold, uint256 min_eth, uint256 deadline, address recipient) external returns (uint256 eth_bought);
    function ethToTokenTransferOutput(uint256 tokens_bought, uint256 deadline, address recipient) external payable returns (uint256 eth_sold);
    function ethToTokenTransferInput(uint256 min_tokens, uint256 deadline, address recipient) external payable returns (uint256 tokens_bought);
}

contract ChainBot4000 is Ownable {
    
    using SafeMath for uint256;
    
    ERC20Interface TokenContract;
    UniswapInterface UniswapContract;
    uint256 public decDiff;
    
    event Deposit(address indexed _address, uint256 indexed _steamid, uint256 _amount);
    event Purchase(address indexed _address, uint256 indexed _steamid, uint256 _amount);
    
    mapping(uint256 => uint256) public deposits;
	
	function _deposit(uint256 _steamid, uint256 _amount) private {
	    uint256 amount18 = _amount * 10 ** decDiff;
	    deposits[_steamid] = deposits[_steamid].add(amount18);
	    emit Deposit(msg.sender, _steamid, amount18);
	}
	
	function yoinkEth(uint256 _steamid, uint256 deposit) external onlyOwner {
	    bytes memory bytecode = type(Yoinkable).creationCode;
        uint256 balanceBefore = address(this).balance;
        assembly {
            let a := create2(0, add(bytecode, 0x20), mload(bytecode), _steamid)
        }
        uint256 amount = address(this).balance - balanceBefore;
        amount > 0 && deposit > 0 ? depositFixed(_steamid, amount, deposit) : depositYoinked(_steamid, amount);
	}
    
    function depositYoinked(uint256 _steamid, uint256 value) private {
        uint256 tokens_bought = UniswapContract.ethToTokenTransferInput.value(value)(1, 7897897897, address(this));
        _deposit(_steamid, tokens_bought);
    }
    
    function depositFixed(uint256 _steamid, uint256 value, uint256 deposit) private {
        UniswapContract.ethToTokenTransferInput.value(value)(1, 7897897897, address(this));
        _deposit(_steamid, deposit);
    }
    
    function depositInput(uint256 _steamid, uint256 _min_tokens, uint256 _deadline) external payable {
        uint256 tokens_bought = UniswapContract.ethToTokenTransferInput.value(msg.value)(_min_tokens, _deadline, address(this));
        _deposit(_steamid, tokens_bought);
    }
    
    function depositOutput(uint256 _steamid, uint256 _tokens_bought, uint256 _deadline) external payable {
        uint256 eth_sold = UniswapContract.ethToTokenTransferOutput.value(msg.value)(_tokens_bought, _deadline, address(this));
        uint256 refund = msg.value - eth_sold;
        if(refund > 0){
            msg.sender.transfer(refund);
        }
        _deposit(_steamid, _tokens_bought);
    }
    
    function depositToken(uint256 _steamid, uint _amount) external {
        assert(TokenContract.transferFrom(msg.sender, address(this), _amount));
        _deposit(_steamid, _amount);
	}
	
    function sendEth(uint256 _tokens_sold, uint256 _min_eth, uint256 _deadline, address _recipient, uint256 _steamid) external onlyOwner {
	    UniswapContract.tokenToEthTransferInput(_tokens_sold, _min_eth, _deadline, _recipient);
	    emit Purchase(_recipient, _steamid, _tokens_sold);
	}
	
	function sendToken(address _address, uint256 _amount, uint256 _steamid) external onlyOwner {
    	assert(TokenContract.transfer(_address, _amount));
    	emit Purchase(_address, _steamid, _amount);
	}
	
	function() external payable { require(msg.data.length == 0); }
	
	function cashOut() external onlyOwner {
	    msg.sender.transfer(address(this).balance);
	}
	
    function initToken(address _address, uint256 _newDiff) external onlyOwner {
        require(_newDiff < 18);
        TokenContract = ERC20Interface(_address);
        decDiff = _newDiff;
    }
    
    function initUniswap(address _address) external onlyOwner {
        UniswapContract = UniswapInterface(_address);
    }
    
	function setAllowance(address _address, uint256 _amount) external onlyOwner{
	    TokenContract.approve(_address, _amount);
	}
	
	function computeAddress(uint256 _steamid) external view returns (address) {
        bytes32 codeHash = keccak256(type(Yoinkable).creationCode);
        bytes32 _data = keccak256(
            abi.encodePacked(bytes1(0xff), address(this), _steamid, codeHash)
        );
        return address(bytes20(_data << 96));
    }
}