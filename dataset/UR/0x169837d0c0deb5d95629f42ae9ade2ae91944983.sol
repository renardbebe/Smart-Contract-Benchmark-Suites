 

pragma solidity ^0.4.24;

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
    function exp(uint a, uint b) internal pure returns (uint c) {
        require(b >= 0 && a >= 0);
        c = a ** b;
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

contract TokenCore is ERC20Interface {
    using SafeMath for uint;

    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)];
    }

    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }

    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function () public payable {
        revert();
    }
}

contract SmartsToken is TokenCore, Owned {
     
    bool public stop;
    uint public feeRate;
    address public feeAccount;
    
    struct UnderlyingToken {
        address tokenAddress;
        uint ratioMultiplier;
        uint truncateDivision;
        mapping(address => uint) reservedBalances;
    }
    
    uint public numbersOfReservedTokens = 3;
    UnderlyingToken[3] public tokens;
    
    event DepositToken(uint tokenId, address token, address indexed from, uint amount);
    event WithdrawReservedToken(uint tokenId, address token, address indexed to, uint amount);
    event SmartsTokenCreation(address indexed creator, uint tokens);
    event SmartsTokenDestroyed(address indexed withdrawer, uint tokens);
    event WithdrawStatusChange(bool stop);
    event FeeAccountTransfered(address feeAccount);
    event TokenValueTruncation(uint tokenId, address token, address indexed from, uint value);
    event FeeRateChanged(uint rate);
    
    constructor (
        address[3] addressesOfTokens,
        uint[3] combinedRatios,
        uint[3] tokenDecimals,
        uint fee,
        address receiveFee
    ) public {
          

         
symbol = 'SC'; name = 'StableCash'; decimals = 6;
        _totalSupply = 0;
        stop = false;
        
        uint multiplier = 10;
        for (uint i = 0; i < numbersOfReservedTokens; i++) {
          tokens[i] = UnderlyingToken(addressesOfTokens[i], combinedRatios[i], multiplier.exp(tokenDecimals[i].sub(decimals)));
        }

        feeRate = fee;
        feeAccount = receiveFee;
    }
        
      function depositToken(uint tokenId, uint amount) public returns (bool success) {
         
         
         
        require (0 <= tokenId && tokenId < numbersOfReservedTokens);
        UnderlyingToken storage token = tokens[tokenId];
        require (ERC20Interface(token.tokenAddress).transferFrom(msg.sender, this, amount));
        
        uint balanceValue = amount;
        if (token.truncateDivision != 1) {
            balanceValue = balanceValue.div(token.truncateDivision).mul(token.truncateDivision);
            uint truncatedValue = amount.sub(balanceValue);
            if (truncatedValue != 0) {
                token.reservedBalances[feeAccount] = token.reservedBalances[feeAccount].add(truncatedValue);
                emit TokenValueTruncation(tokenId, token.tokenAddress, msg.sender, truncatedValue);                
            }
        }
        
        token.reservedBalances[msg.sender] = token.reservedBalances[msg.sender].add(balanceValue);
        emit DepositToken(tokenId, token.tokenAddress, msg.sender, balanceValue);
        return true;
      }

    function withdrawReservedToken(uint tokenId, uint amount) public returns (bool success) {
        require (!stop);
        require (0 <= tokenId && tokenId < numbersOfReservedTokens);
        UnderlyingToken storage token = tokens[tokenId];
        require (token.reservedBalances[msg.sender] >= amount);
        token.reservedBalances[msg.sender] = token.reservedBalances[msg.sender].sub(amount);
        ERC20Interface(token.tokenAddress).transfer(msg.sender, amount);
        emit WithdrawReservedToken(tokenId, token.tokenAddress, msg.sender, amount);
        return true;
    }

    function tokenReservedBalanceOf(uint tokenId, address tokenOwner) public constant returns (uint balance) {
        require (0 <= tokenId && tokenId < numbersOfReservedTokens);
        UnderlyingToken storage token = tokens[tokenId];
        return token.reservedBalances[tokenOwner];
    }
    
    function convertToSmarts(uint amount) public returns (bool success) {
        for (uint i = 0; i < numbersOfReservedTokens; i++) {
          UnderlyingToken storage token = tokens[i];
          require (token.reservedBalances[msg.sender] >= amount.mul(token.ratioMultiplier).mul(token.truncateDivision));
        }

        for (i = 0; i < numbersOfReservedTokens; i++) {
          token = tokens[i];
          token.reservedBalances[msg.sender] = token.reservedBalances[msg.sender].sub(amount.mul(token.ratioMultiplier).mul(token.truncateDivision));
        }
        
        _totalSupply = _totalSupply.add(amount);
        uint fee = amount.div(feeRate);
        uint afterfee = amount.sub(fee);
        balances[msg.sender] = balances[msg.sender].add(afterfee);
        balances[feeAccount] = balances[feeAccount].add(fee);
        
        emit SmartsTokenCreation(msg.sender, amount);
        emit Transfer(address(0), msg.sender, afterfee);
        emit Transfer(msg.sender, feeAccount, fee);            
        return true;
    }
    
    
    function withdrawTokens(uint amount) public returns (bool success) {
        require (!stop);
        require (balances[msg.sender] >= amount);

        uint receive;
         
        if (msg.sender == feeAccount) {
            receive = amount;
        } else {
            uint fee = amount.div(feeRate);
            uint afterfee = amount.sub(fee);
            receive = afterfee;
            balances[feeAccount] = balances[feeAccount].add(fee);
            emit Transfer(msg.sender, feeAccount, fee);            
        }
        
        for (uint i = 0; i < numbersOfReservedTokens; i++) {
            UnderlyingToken storage token = tokens[i];
            ERC20Interface(token.tokenAddress).transfer(msg.sender, receive.mul(token.ratioMultiplier).mul(token.truncateDivision));
        }
        
        balances[msg.sender] = balances[msg.sender].sub(amount);
            
        _totalSupply = _totalSupply.sub(receive);
        emit SmartsTokenDestroyed(msg.sender, receive);
        emit Transfer(msg.sender, address(0), receive);        
        return true;
     }
    
    function changeFeeRate(uint rate) public onlyOwner returns (bool success) {
        feeRate = rate;
        emit FeeRateChanged(rate);
        return true;
    }
    
    function changeFeeAccount(address newFeeAccount) public onlyOwner returns (bool success) {
        feeAccount = newFeeAccount;
        emit FeeAccountTransfered(newFeeAccount);
        return true;
    }
    
    function toggleWithdrawStatus() public onlyOwner returns (bool success) {
        if (stop) {
            stop = false;
            emit WithdrawStatusChange(false);            
        } else {
            stop = true;
            emit WithdrawStatusChange(true);
        }
        return true;
     }
}