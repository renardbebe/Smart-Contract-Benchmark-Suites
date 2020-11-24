 

pragma solidity ^0.5.10;

 
 
 
 
 
 
 
 
 
 
 


 
 
 
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b > 0);
        c = a / b;
    }
}


 
 
 
 
interface ERC20Interface {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint256 balance);
    function allowance(address tokenOwner, address spender) external view returns (uint256 remaining);
    function transfer(address to, uint256 tokens) external returns (bool success);
    function approve(address spender, uint256 tokens) external returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}


 
 
 
 
 
interface ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes calldata data) external;
}


 
 
 
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

 
 
 
interface MedianiserInterface {
    function read() external view returns (bytes32);
}

 
 
 
 
 
 
contract PEG is ERC20Interface, Owned {
    using SafeMath for uint;

    string public symbol;
    string public  name;
    uint8 public decimals;
    uint256 _totalSupply;
    uint256 lastPriceAdjustment;
    uint256 timeBetweenPriceAdjustments;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    
    MedianiserInterface medianiser;
    
    event Burn(address indexed tokenOwner, uint256 tokens);
    event gotPEG(address indexed caller, uint256 amountGivenEther, uint256 amountReceivedPEG);
    event gotEther(address indexed caller, uint256 amountGivenPEG, uint256 amountReceivedEther);
    event Inflate(uint256 previousPoolSize, uint256 amountMinted);
    event Deflate(uint256 previousPoolSize, uint256 amountBurned);

    
     
     
    constructor() payable public {
        symbol = "PEG";
        name = "PEG Stablecoin";
        decimals = 18;
        lastPriceAdjustment = now;
        timeBetweenPriceAdjustments = 60*60;
        
         
         
        medianiser = MedianiserInterface(0x729D19f657BD0614b4985Cf1D82531c67569197B);  
        _totalSupply = getPriceETH_USD().mul(address(this).balance).div(10**uint(decimals));
        balances[address(this)] = _totalSupply;
    }


     
     
     
     
     
    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }


     
     
     
     
     
     
    function balanceOf(address tokenOwner) public view returns (uint256 balance) {
        return balances[tokenOwner];
    }


     
     
     
     
     
     
     
    function transfer(address to, uint256 tokens) public returns (bool success) {
        require(to != address(0));
        if (to == address(this)) getEther(tokens);
        else {
            balances[msg.sender] = balances[msg.sender].sub(tokens);
            balances[to] = balances[to].add(tokens);
            emit Transfer(msg.sender, to, tokens);
        }
        return true;
    }
    
     
     
     
     
     
     
    function burn(uint256 tokens) public returns (bool success) {
        _totalSupply = _totalSupply.sub(tokens);
        balances[msg.sender] -= balances[msg.sender].sub(tokens);
        emit Burn(msg.sender, tokens);
        return true;
    }


     
     
     
     
     
     
     
    function approve(address spender, uint256 tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }


     
     
     
     
     
     
     
     
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }


     
     
     
     
     
     
     
    function allowance(address tokenOwner, address spender) public view returns (uint256 allowancePEG) {
        return allowed[tokenOwner][spender];
    }


     
     
     
     
     
     
     
    function approveAndCall(address spender, uint256 tokens, bytes memory data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }


     
     
     
    function () external payable {
        getPEG();
    }
    
    modifier canTriggerPriceAdjustment {
        _;
        if (now >= lastPriceAdjustment + timeBetweenPriceAdjustments) priceFeedAdjustment();
    }
    
    function getNextPriceAdjustmentTime() public view returns (uint256 nextPriceAdjustmentTime) {
        if (now >= lastPriceAdjustment + timeBetweenPriceAdjustments) return 0;
        else return lastPriceAdjustment + timeBetweenPriceAdjustments - now;
    }
    
    function getPEG() public payable canTriggerPriceAdjustment returns (bool success, uint256 amountReceivedPEG) {
        amountReceivedPEG = balances[address(this)].mul(msg.value.mul(10**5).div(address(this).balance)).div(10**5);
        balances[address(this)] = balances[address(this)].sub(amountReceivedPEG);
        balances[msg.sender] = balances[msg.sender].add(amountReceivedPEG);
        emit gotPEG(msg.sender, msg.value, amountReceivedPEG);
        return (true, amountReceivedPEG);
    }
    
    function getEther(uint256 amountGivenPEG) public canTriggerPriceAdjustment returns (bool success, uint256 amountReceivedEther) {
        amountReceivedEther = address(this).balance.mul(amountGivenPEG.mul(10**5).div(balanceOf(address(this)).add(amountGivenPEG))).div(10**5);
        balances[address(this)] = balances[address(this)].add(amountGivenPEG);
        balances[msg.sender] = balances[msg.sender].sub(amountGivenPEG);
        emit gotEther(msg.sender, amountGivenPEG, amountReceivedEther);
        msg.sender.transfer(amountReceivedEther);
        return (true, amountReceivedEther);
    }
    
    function getPoolBalances() public view returns (uint256 balanceETH, uint256 balancePEG) {
        return (address(this).balance, balanceOf(address(this)));
    }
    
    function inflateEtherPool() public payable returns (bool success) {
        return true;
    }
    
    function getPriceETH_USD() public view returns (uint256 priceETH_USD) {
        bytes32 price = medianiser.read();
        return uint(price);
    }
    
    function priceFeedAdjustment() private returns (uint256 newRatePEG) {
        uint256 feedPrice = getPriceETH_USD().mul(address(this).balance).div(10**uint(decimals));
        if (feedPrice > balances[address(this)]) {
            uint256 posDelta = feedPrice.sub(balances[address(this)]).div(10);
            newRatePEG = balances[address(this)].add(posDelta);
            emit Inflate(balances[address(this)], posDelta);
            balances[address(this)] = newRatePEG;
            _totalSupply = _totalSupply.add(posDelta);
        } else if (feedPrice < balances[address(this)]) {
            uint256 negDelta = balances[address(this)].sub(feedPrice).div(10);
            newRatePEG = balances[address(this)].sub(negDelta);
            emit Deflate(balances[address(this)], negDelta);
            balances[address(this)] = newRatePEG;
            _totalSupply = _totalSupply.sub(negDelta);
        } else {
            newRatePEG = balances[address(this)];
        }
        lastPriceAdjustment = now;
    }

     
     
     
    function transferAnyERC20Token(address tokenAddress, uint256 tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
    
    function dumpContractCode() public view returns (bytes memory o_code) {
        address _addr = address(this);
        assembly {
             
            let size := extcodesize(_addr)
             
             
            o_code := mload(0x40)
             
            mstore(0x40, add(o_code, and(add(add(size, 0x20), 0x1f), not(0x1f))))
             
            mstore(o_code, size)
             
            extcodecopy(_addr, add(o_code, 0x20), 0, size)
        }
    }
}