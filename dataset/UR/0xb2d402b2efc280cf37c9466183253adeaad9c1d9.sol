 

pragma solidity ^0.4.4;

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

contract Token {
     
    function totalSupply() public constant returns (uint256 supply) {}

     
     
    function balanceOf(address _owner) public constant returns (uint256 balance) {}

     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool success) {}

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {}

     
     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success) {}

     
     
     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    event Burn(address indexed from, uint256 value);
}


contract StandardToken is Token, SafeMath {
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;

    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);

        emit Transfer(msg.sender, to, tokens);

        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);

        emit Transfer(from, to, tokens);

        return true;
    }

    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }

    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;

        emit Approval(msg.sender, spender, tokens);

        return true;
    }

    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


    function burn(uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);                          
        balances[msg.sender] = safeSub(balances[msg.sender], _value);     
        totalSupply = safeSub(totalSupply,_value);                        

        emit Burn(msg.sender, _value);

        return true;
    }

     
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balances[_from] >= _value);                                         
        require(_value <= allowed[_from][msg.sender]);                              
        balances[_from] = safeSub(balances[_from],_value);                          
        allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender],_value);    
        totalSupply = safeSub(totalSupply,_value);                                  
        emit    Burn(_from, _value);
        return true;
    }
}

contract CryptonCoin is StandardToken {
    string public name;
    uint8 public decimals;
    string public symbol;
    string public version = 'H1.0';
    address public fundsWallet;
    address public contractAddress;

    uint256 public preIcoSupply;
    uint256 public preIcoTotalSupply;

    uint256 public IcoSupply;
    uint256 public IcoTotalSupply;

    uint256 public maxSupply;
    uint256 public totalSupply;

    uint256 public unitsOneEthCanBuy;
    uint256 public totalEthInWei;

    bool public ico_finish;
    bool public token_was_created;

    uint256 public preIcoFinishTimestamp;
    uint256 public fundingEndTime;
    uint256 public finalTokensIssueTime;

    function CryptonCoin() public {
        fundsWallet = msg.sender;

        name = "CRYPTON";
        symbol = "CRN";
        decimals = 18;

        balances[fundsWallet] = 0;
        totalSupply       = 0;
        preIcoTotalSupply = 14400000000000000000000000;
        IcoTotalSupply    = 36000000000000000000000000;
        maxSupply         = 72000000000000000000000000;
        unitsOneEthCanBuy = 377;

        preIcoFinishTimestamp = 1524785992;  
        fundingEndTime        = 1528587592;  
        finalTokensIssueTime  = 1577921992;  

        contractAddress = address(this);
    }

    function() public payable {
        require(!ico_finish);
        require(block.timestamp < fundingEndTime);
        require(msg.value != 0);

        totalEthInWei = totalEthInWei + msg.value;
        uint256  amount = 0;
        uint256 tokenPrice = unitsOneEthCanBuy;

        if (block.timestamp < preIcoFinishTimestamp) {
            require(msg.value * tokenPrice * 7 / 10 <= (preIcoTotalSupply - preIcoSupply));

            tokenPrice = safeMul(tokenPrice,7);
            tokenPrice = safeDiv(tokenPrice,10);

            amount = safeMul(msg.value,tokenPrice);
            preIcoSupply = safeAdd(preIcoSupply,amount);

            balances[msg.sender] = safeAdd(balances[msg.sender],amount);
            totalSupply = safeAdd(totalSupply,amount);

            emit Transfer(contractAddress, msg.sender, amount);
        } else {
            require(msg.value * tokenPrice <= (IcoTotalSupply - IcoSupply));

            amount = safeMul(msg.value,tokenPrice);
            IcoSupply = safeAdd(IcoSupply,amount);
            balances[msg.sender] = safeAdd(balances[msg.sender],amount);
            totalSupply = safeAdd(totalSupply,amount);

            emit Transfer(contractAddress, msg.sender, amount);
        }
    }

    function withdraw() public {
        if (block.timestamp > fundingEndTime) {
            fundsWallet.transfer(contractAddress.balance);
        }
    }

    function createTokensForCrypton() public returns (bool success) {
        require(ico_finish);
        require(!token_was_created);

        if (block.timestamp > finalTokensIssueTime) {
            uint256 amount = safeAdd(preIcoSupply, IcoSupply);
            amount = safeMul(amount,3);
            amount = safeDiv(amount,10);

            balances[fundsWallet] = safeAdd(balances[fundsWallet],amount);
            totalSupply = safeAdd(totalSupply,amount);
            emit Transfer(contractAddress, fundsWallet, amount);
            token_was_created = true;
            return true;
        }
    }

    function stopIco() public returns (bool success) {
        if (block.timestamp > fundingEndTime) {
            ico_finish = true;
            return true;
        }
    }

    function setTokenPrice(uint256 _value) public returns (bool success) {
        require(msg.sender == fundsWallet);
        require(_value < 1500);
        unitsOneEthCanBuy = _value;
        return true;
    }
}