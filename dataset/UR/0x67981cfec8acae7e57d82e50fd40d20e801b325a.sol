 

pragma solidity ^0.4.21;

 

 
 

contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}


contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Owned() public {
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
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract CCLToken is ERC20Interface, Owned, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;


    function CCLToken() public {
        symbol = "CCL";
        name = "CyClean Token";
        decimals = 18;
        _totalSupply = 4000000000000000000000000000;  
        balances[0xf835bF0285c99102eaedd684b4401272eF36aF65] = _totalSupply;
        Transfer(address(0), 0xf835bF0285c99102eaedd684b4401272eF36aF65, _totalSupply);
    }


    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)];
    }


    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }


    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        Transfer(msg.sender, to, tokens);
        return true;
    }


    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        return true;
    }


    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        Transfer(from, to, tokens);
        return true;
    }


    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }


    function () public payable {
        revert();
    }


    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}

 

contract ICOEngineInterface {

     
    function started() public view returns(bool);

     
    function ended() public view returns(bool);

     
    function startTime() public view returns(uint);

     
    function endTime() public view returns(uint);

     
     
     

     
     
     

     
    function totalTokens() public view returns(uint);

     
     
    function remainingTokens() public view returns(uint);

     
    function price() public view returns(uint);
}

 

library SafeMathLib {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c>=a && c>=b);
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
}

 

 
contract KYCBase {
    using SafeMathLib for uint256;

    mapping (address => bool) public isKycSigner;
    mapping (uint64 => uint256) public alreadyPayed;

    event KycVerified(address indexed signer, address buyerAddress, uint64 buyerId, uint maxAmount);
    event ThisCheck(KYCBase base, address sender);
    constructor ( address[] kycSigners) internal {
        for (uint i = 0; i < kycSigners.length; i++) {
            isKycSigner[kycSigners[i]] = true;
        }
    }

     
    function releaseTokensTo(address buyer) internal returns(bool);

     
    function senderAllowedFor(address buyer)
        internal view returns(bool)
    {
        return buyer == msg.sender;
    }

    function buyTokensFor(address buyerAddress, uint64 buyerId, uint maxAmount, uint8 v, bytes32 r, bytes32 s)
        public payable returns (bool)
    {
        require(senderAllowedFor(buyerAddress));
        return buyImplementation(buyerAddress, buyerId, maxAmount, v, r, s);
    }

    function buyTokens(uint64 buyerId, uint maxAmount, uint8 v, bytes32 r, bytes32 s)
        public payable returns (bool)
    {
        return buyImplementation(msg.sender, buyerId, maxAmount, v, r, s);
    }

    function buyImplementation(address buyerAddress, uint64 buyerId, uint maxAmount, uint8 v, bytes32 r, bytes32 s)
        private returns (bool)
    {
         
        bytes32 hash = sha256(abi.encodePacked("Eidoo icoengine authorization", this, buyerAddress, buyerId, maxAmount));
        emit ThisCheck(this, msg.sender);
         
        address signer = ecrecover(hash, v, r, s);
        if (!isKycSigner[signer]) {
            revert();
        } else {
            uint256 totalPayed = alreadyPayed[buyerId].add(msg.value);
            require(totalPayed <= maxAmount);
            alreadyPayed[buyerId] = totalPayed;
            emit KycVerified(signer, buyerAddress, buyerId, maxAmount);
            return releaseTokensTo(buyerAddress);
        }
    }

     
    function () public {
        revert();
    }
}

 

contract TokenSale is ICOEngineInterface, KYCBase {
    using SafeMathLib for uint;

    event ReleaseTokensToCalled(address buyer);

    event ReleaseTokensToCalledDetail(address wallet, address buyer, uint amount, uint remainingTokensValue);
    event SenderCheck(address sender);

    CCLToken public token;
    address public wallet;

     
    uint private priceValue;
    function price() public view returns(uint) {
        return priceValue;
    }

     
    uint private startTimeValue;
    function startTime() public view returns(uint) {
        return startTimeValue;
    }

     
    uint private endTimeValue;
    function endTime() public view returns(uint) {
        return endTimeValue;
    }
     
    uint private totalTokensValue;
    function totalTokens() public view returns(uint) {
        return totalTokensValue;
    }

     
    uint private remainingTokensValue;
    function remainingTokens() public view returns(uint) {
        return remainingTokensValue;
    }


     
    constructor ( address[] kycSigner, CCLToken _token, address _wallet, uint _startTime, uint _endTime, uint _price, uint _totalTokens)
        public KYCBase(kycSigner)
    {
        token = _token;
        wallet = _wallet;
         
        startTimeValue = _startTime;
        endTimeValue = _endTime;
        priceValue = _price;
        totalTokensValue = _totalTokens;
        remainingTokensValue = _totalTokens;
    }

     
    function releaseTokensTo(address buyer) internal returns(bool) {
         
        require(now >= startTimeValue && now < endTimeValue);
        uint amount = msg.value.mul(priceValue);
        remainingTokensValue = remainingTokensValue.sub(amount);
        emit ReleaseTokensToCalledDetail(wallet, buyer, amount, remainingTokensValue);

        wallet.transfer(msg.value);
         
        token.transferFrom(wallet, buyer, amount);
        emit ReleaseTokensToCalled(buyer);
        return true;
    }

     
    function started() public view returns(bool) {
        return now >= startTimeValue;
    }

     
    function ended() public view returns(bool) {
        return now >= endTimeValue || remainingTokensValue == 0;
    }

    function senderAllowedFor(address buyer)
        internal view returns(bool)
    {
        bool value = super.senderAllowedFor(buyer);
        return value;
    }
}