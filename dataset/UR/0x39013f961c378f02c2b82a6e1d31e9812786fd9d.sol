 

pragma solidity ^0.4.8;

 

library SMSLIB {
     
    function safeDiv(uint a, uint b) pure internal returns(uint) {
         
        assert(b > 0);
        uint c = a / b;
        assert(a == b * c + a % b);
        return c;
    }
}

contract ERC20 {
     
    function totalSupply() public constant returns(uint256 _totalSupply);
    function balanceOf(address who) public constant returns(uint256 balance);
    function transfer(address to, uint value) public returns(bool success);
    function transferFrom(address from, address to, uint value) public returns(bool success);
    function approve(address spender, uint value) public returns(bool success);
    function allowance(address owner, address spender) public constant returns(uint remaining);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract SMSCoin is ERC20 {
    string public constant name = "Speed Mining Service";
    string public constant symbol = "SMS";
    uint256 public constant decimals = 3;

    uint256 public constant UNIT = 10 ** decimals;

    uint public totalSupply = 0;  

    uint tokenSaleLot1 = 150000 * UNIT;
    uint reservedBonusLot1 = 45000 * UNIT;  
    uint tokenSaleLot3X = 50000 * UNIT;

    struct BonusStruct {
        uint8 ratio1;
        uint8 ratio2;
        uint8 ratio3;
        uint8 ratio4;
    }
    BonusStruct bonusRatio;

    uint public saleCounterThisPhase = 0;

    uint public limitedSale = 0;

    uint public sentBonus = 0;

    uint public soldToken = 0;

    mapping(address => uint) balances;

    mapping(address => mapping(address => uint)) allowed;

    address[] addresses;
    address[] investorAddresses;

    mapping(address => address) private userStructs;

    address owner;

    address mint = address(this);    
    
    address genesis = 0x0;

    uint256 public tokenPrice = 0.8 ether;
    uint256 public firstMembershipPurchase = 0.16 ether;    

    event Log(uint e);

    event Message(string msg);

    event TOKEN(string e);

    bool icoOnSale = false;

    bool icoOnPaused = false;

    bool spPhase = false;

    uint256 startDate;

    uint256 endDate;

    uint currentPhase = 0;

    bool needToDrain = false;

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert();
        }
        _;
    }

    function SMSCoin() public {
        owner = msg.sender;
    }

    function setBonus(uint8 ratio1, uint8 ratio2, uint8 ratio3, uint8 ratio4) private {
        bonusRatio.ratio1 = ratio1;
        bonusRatio.ratio2 = ratio2;
        bonusRatio.ratio3 = ratio3;
        bonusRatio.ratio4 = ratio4;
    }

    function calcBonus(uint256 sendingSMSToken) view private returns(uint256) {
         
        if (sendingSMSToken < (10 * UNIT)) {             
            return (sendingSMSToken * bonusRatio.ratio1) / 100;
        } else if (sendingSMSToken < (50 * UNIT)) {      
            return (sendingSMSToken * bonusRatio.ratio2) / 100;
        } else if (sendingSMSToken < (100 * UNIT)) {     
            return (sendingSMSToken * bonusRatio.ratio3) / 100;
        } else {                                         
            return (sendingSMSToken * bonusRatio.ratio4) / 100;
        }
    }

     
    function () public payable {
        uint256 receivedETH = 0;
        uint256 receivedETHUNIT = 0;
        uint256 sendingSMSToken = 0;
        uint256 sendingSMSBonus = 0;
        Log(msg.value);

         
        if (icoOnSale && !icoOnPaused && msg.sender != owner) {
            if (now <= endDate) {
                 
                Log(currentPhase);
                
                receivedETH = msg.value;
                 
                 
                if ((checkAddress(msg.sender) && checkMinBalance(msg.sender)) || firstMembershipPurchase <= receivedETH) {
                     
                    receivedETHUNIT = receivedETH * UNIT;
                    sendingSMSToken = SMSLIB.safeDiv(receivedETHUNIT, tokenPrice);
                    Log(sendingSMSToken);

                     
                    if (currentPhase == 1 || currentPhase == 2 || currentPhase == 3) {
                         
                        sendingSMSBonus = calcBonus(sendingSMSToken);
                        Log(sendingSMSBonus);
                    }

                     
                    Log(sendingSMSToken);
                    if (!transferTokens(msg.sender, sendingSMSToken, sendingSMSBonus))
                        revert();
                } else {
                     
                    revert();
                }
            } else {
                 
                revert();
            }
        } else {
             
            revert();
        }
    }

     
     
     
     
     
     
     
     
     
    function start1BonusPeriod1() external onlyOwner {
         
        require(currentPhase == 0);

        balances[owner] = tokenSaleLot1;  
        balances[address(this)] = tokenSaleLot1;   
        totalSupply = balances[owner] + balances[address(this)];
        saleCounterThisPhase = 0;
        limitedSale = tokenSaleLot1;

         
        addAddress(owner);

         
        Transfer(address(this), owner, balances[owner]);

         
        needToDrain = true;

         
        icoOnSale = true;
        icoOnPaused = false;
        spPhase = false;
        currentPhase = 1;
        startDate = block.timestamp;
        endDate = startDate + 2 days + 9 hours + 59 minutes + 59 seconds;

         
        setBonus(5, 10, 20, 30);
    }

     
     
     
     
     
     
     
     
     
    function start2BonusPeriod2() external onlyOwner {
         
        icoOnSale = true;
        icoOnPaused = false;
        spPhase = false;
        currentPhase = 2;
        startDate = block.timestamp;
        endDate = startDate + 11 days + 9 hours + 59 minutes + 59 seconds;

         
        setBonus(3, 5, 10, 15);
    }

     
     
     
     
     
     
     
     
     
    function start3BonusPeriod3() external onlyOwner {
         
        icoOnSale = true;
        icoOnPaused = false;
        spPhase = false;
        currentPhase = 3;
        startDate = block.timestamp;
        endDate = startDate + 50 days + 5 hours + 14 minutes + 59 seconds;

         
        setBonus(1, 3, 5, 8);
    }

     
     
     
     
    function start4NormalPeriod() external onlyOwner {
         
        icoOnSale = true;
        icoOnPaused = false;
        spPhase = false;
        currentPhase = 4;
        startDate = block.timestamp;
        endDate = startDate + 31 days;

         
        setBonus(0, 0, 0, 0);
    }

     
     
     
     
     
     

     
     
     
     
     
     
    function start3XPhase() external onlyOwner {
         
        require(currentPhase == 4 || currentPhase == 5);
            
         
        require(!needToDrain);
            
        balances[address(this)] = tokenSaleLot3X;
        totalSupply = 3 * totalSupply;
        totalSupply += balances[address(this)];
        saleCounterThisPhase = 0;
        limitedSale = tokenSaleLot3X;

         
        x3Token();  

         
        Transfer(mint, address(this), balances[address(this)]);
        
         
        needToDrain = true;
        
         
        icoOnSale = true;
        icoOnPaused = false;
        spPhase = false;
        currentPhase = 5;
        startDate = block.timestamp;
        endDate = startDate + 7 days;
    }

     
     
    function startManualPeriod(uint _saleToken) external onlyOwner {
         

         
        require(balances[owner] >= _saleToken);
        
         
        require(!needToDrain);

         
        balances[owner] -= _saleToken;
        balances[address(this)] += _saleToken;
        saleCounterThisPhase = 0;
        limitedSale = _saleToken;
        Transfer(owner, address(this), _saleToken);
        
         
        needToDrain = true;
        
         
        icoOnSale = true;
        icoOnPaused = false;
        spPhase = true;
        startDate = block.timestamp;
        endDate = startDate + 7 days;  
    }

    function x3Token() private {
         
        for (uint i = 0; i < addresses.length; i++) {
            uint curr1XBalance = balances[addresses[i]];
             
            balances[addresses[i]] = 3 * curr1XBalance;
             
            Transfer(mint, addresses[i], 2 * curr1XBalance);
             
            sentBonus += (2 * curr1XBalance);
        }
    }

     
    function endPhase() external onlyOwner {
        icoOnSale = false;
        icoOnPaused = true;
    }

     
    function pausePhase() external onlyOwner {
        icoOnPaused = true;
    }

     
    function resumePhase() external onlyOwner {
        icoOnSale = true;
        icoOnPaused = false;
    }

     
    function extend1Week() external onlyOwner {
        endDate += 7 days;
    }

     
    function totalSupply() public constant returns(uint256 _totalSupply) {
        return totalSupply;
    }

    function balanceOf(address sender) public constant returns(uint256 balance) {
        return balances[sender];
    }

    function soldToken() public constant returns(uint256 _soldToken) {
        return soldToken;
    }

    function sentBonus() public constant returns(uint256 _sentBonus) {
        return sentBonus;
    }

    function saleCounterThisPhase() public constant returns(uint256 _saleCounter) {
        return saleCounterThisPhase;
    }

     
     
    function setTokenPrice(uint ethRate) external onlyOwner {
        tokenPrice = (ethRate * 10 ** 18) / 10000;  
    }

    function setMembershipPrice(uint ethRate) external onlyOwner {
        firstMembershipPurchase = (ethRate * 10 ** 18) / 10000;  
    }

     
    function transfer(address _to, uint256 _amount) public returns(bool success) {
        if (balances[msg.sender] >= _amount && _amount > 0 && balances[_to] + _amount > balances[_to]) {

            balances[msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(msg.sender, _to, _amount);

             
            addAddress(_to);

            return true;
        } else {
            return false;
        }
    }

     
    function transferFrom(address _from, address _to, uint256 _amount) public returns(bool success) {
        if (balances[_from] >= _amount && allowed[_from][msg.sender] >= _amount && _amount > 0 && balances[_to] + _amount > balances[_to]) {
                
            balances[_from] -= _amount;
            allowed[_from][msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

     
     
    function approve(address _spender, uint256 _amount) public returns(bool success) {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

     
    function allowance(address _owner, address _spender) public constant returns(uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
    function transferTokens(address _to, uint256 _amount, uint256 _bonus) private returns(bool success) {
        if (_amount > 0 && balances[address(this)] >= _amount && balances[address(this)] - _amount >= 0 && soldToken + _amount > soldToken && saleCounterThisPhase + _amount <= limitedSale && balances[_to] + _amount > balances[_to]) {
            
             
            balances[address(this)] -= _amount;
            soldToken += _amount;
            saleCounterThisPhase += _amount;
            balances[_to] += _amount;
            Transfer(address(this), _to, _amount);
            
             
            if (currentPhase <= 3 && _bonus > 0 && balances[owner] - _bonus >= 0 && sentBonus + _bonus > sentBonus && sentBonus + _bonus <= reservedBonusLot1 && balances[_to] + _bonus > balances[_to]) {

                 
                balances[owner] -= _bonus;
                sentBonus += _bonus;
                balances[_to] += _bonus;
                Transfer(owner, _to, _bonus);
            }

             
            addAddress(_to);

            return true;
        } else {
            return false;
        }
    }

     
     
     
     
    function giveAways(address _to, uint256 _amount, uint256 _bonus) external onlyOwner {
         
        if (!transferTokens(_to, _amount, _bonus))
            revert();
    }

     
     
     
     
    function giveReward(uint256 _amount) external onlyOwner {
         
        require(balances[owner] >= _amount);

        uint totalInvestorHand = 0;
         
        for (uint idx = 0; idx < investorAddresses.length; idx++) {
            if (checkMinBalance(investorAddresses[idx]))
                totalInvestorHand += balances[investorAddresses[idx]];
        }
        uint valuePerToken = _amount * UNIT / totalInvestorHand;

         
        for (idx = 0; idx < investorAddresses.length; idx++) {
            if (checkMinBalance(investorAddresses[idx])) {
                uint bonusForThisInvestor = balances[investorAddresses[idx]] * valuePerToken / UNIT;
                sentBonus += bonusForThisInvestor;
                balances[owner] -= bonusForThisInvestor;
                balances[investorAddresses[idx]] += bonusForThisInvestor;
                Transfer(owner, investorAddresses[idx], bonusForThisInvestor);
            }
        }
    }

     
    function checkAddress(address _addr) public constant returns(bool exist) {
        return userStructs[_addr] == _addr;
    }

     
    function checkMinBalance(address _addr) public constant returns(bool enough) {
        return balances[_addr] >= (firstMembershipPurchase * 10000 / tokenPrice * UNIT / 10000);
    }
    
     
    function addAddress(address _to) private {
        if (addresses.length > 0) {
            if (userStructs[_to] != _to) {
                userStructs[_to] = _to;
                 
                addresses.push(_to);
                 
                if (_to != address(this) && _to != owner)
                    investorAddresses.push(_to);
            }
        } else {
            userStructs[_to] = _to;
             
            addresses.push(_to);
             
            if (_to != address(this) && _to != owner)
                investorAddresses.push(_to);
        }
    }

     
    function drainETH() external onlyOwner {
        owner.transfer(this.balance);
    }

     
     
    function drainSMS() external onlyOwner {
         
        require(!icoOnSale);

         
        if (currentPhase >= 4 || spPhase) {
             
             
            if (balances[address(this)] > 0) {
                balances[owner] += balances[address(this)];
                Transfer(address(this), owner, balances[address(this)]);
                balances[address(this)] = 0;

                 
                needToDrain = false;
            }
        }
    }

     
     
     
    function hardBurnSMS(address _from, uint _amount) external onlyOwner {
         
        if (balances[_from] > 0) {
            balances[_from] -= _amount;
            totalSupply -= _amount;
            Transfer(_from, genesis, _amount);
        }
    }

     
    function getAddress(uint i) public constant returns(address) {
        return addresses[i];
    }

     
    function getAddressSize() public constant returns(uint) {
        return addresses.length;
    }
}