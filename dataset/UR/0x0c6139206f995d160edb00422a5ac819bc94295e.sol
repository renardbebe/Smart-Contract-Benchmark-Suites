 

pragma solidity ^0.5.1;

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
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
        return msg.sender == _owner;
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

library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
         
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
         

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
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

contract ChainBot3000 is Ownable {
    
    using SafeMath for uint256;
    
    ERC20Interface DaiContract;
    UniswapInterface UniswapContract;
    
    event Deposit(address indexed _address, bytes32 indexed _steamid, uint256 _amount);
    event Deposit(address indexed _address, bytes32 indexed _steamid, uint256 _amount, uint256 _value);
    event Purchase(address indexed _address, bytes32 indexed _steamid, bytes32 _offerid, uint256 _amount);
    event Purchase(address indexed _address, bytes32 indexed _steamid, bytes32 _offerid, uint256 _amount, uint256 _value);

    mapping(bytes32 => uint256) public deposits;
    
    constructor(address _daiAddress, address _uniswapAddress) public {
        initDai(_daiAddress);
        initUniswap(_uniswapAddress);
        setAllowance(_uniswapAddress, uint256(-1));
    }
    
    function initDai(address _address) public onlyOwner {
        DaiContract = ERC20Interface(_address);
    }
    
    function initUniswap(address _address) public onlyOwner {
        UniswapContract = UniswapInterface(_address);
    }
    
	function setAllowance(address _address, uint256 _amount) public onlyOwner returns (bool){
	    return DaiContract.approve(_address, _amount);
	}
	
    function depositOutput(bytes32 _steamid, uint256 _tokens_bought, uint256 _deadline) external payable {
        uint256 eth_sold = UniswapContract.ethToTokenTransferOutput.value(msg.value)(_tokens_bought, _deadline, address(this));
        uint256 refund = msg.value - eth_sold;
        if(refund > 0){
            msg.sender.transfer(refund);
        }
        deposits[_steamid] = deposits[_steamid].add(_tokens_bought);
        emit Deposit(msg.sender, _steamid, _tokens_bought, eth_sold);
    }
    
    function depositInput(bytes32 _steamid, uint256 _min_tokens, uint256 _deadline) external payable {
        uint256 tokens_bought = UniswapContract.ethToTokenTransferInput.value(msg.value)(_min_tokens, _deadline, address(this));
        deposits[_steamid] = deposits[_steamid].add(tokens_bought);
        emit Deposit(msg.sender, _steamid, tokens_bought, msg.value);
    }
    
    function depositDai(bytes32 _steamid, uint _amount) external {
        assert(DaiContract.transferFrom(msg.sender, address(this), _amount));
        deposits[_steamid] = deposits[_steamid].add(_amount);
        emit Deposit(msg.sender, _steamid, _amount);
	}
	
    function sendEth(uint256 _tokens_sold, uint256 _min_eth, uint256 _deadline, address _recipient, bytes32 _steamid, bytes32 _offerid) external onlyOwner {
	    uint256 eth_bought = UniswapContract.tokenToEthTransferInput(_tokens_sold, _min_eth, _deadline, _recipient);
	    emit Purchase(_recipient, _steamid, _offerid, _tokens_sold, eth_bought);
	}
	
	function sendDai(address _address, uint256 _amount, bytes32 _steamid, bytes32 _offerid) external onlyOwner {
    	assert(DaiContract.transfer(_address, _amount));
    	emit Purchase(_address, _steamid, _offerid, _amount);
	}
	
	function() external payable { require(msg.data.length == 0); }
	
	function cashOut() external onlyOwner {
	    msg.sender.transfer(address(this).balance);
	}
}