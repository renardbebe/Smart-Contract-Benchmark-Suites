 

pragma solidity ^0.4.8;

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
    uint tokenSaleLot2 = 50000 * UNIT;
    uint tokenSaleLot3 = 50000 * UNIT;

    struct BonusStruct {
        uint8 ratio1;
        uint8 ratio2;
        uint8 ratio3;
        uint8 ratio4;
    }
    BonusStruct bonusRatio;

    uint public saleCounter = 0;

    uint public limitedSale = 0;

    uint public sentBonus = 0;

    uint public soldToken = 0;

    mapping(address => uint) balances;

    mapping(address => mapping(address => uint)) allowed;

    address[] addresses;

    mapping(address => address) private userStructs;

    address owner;

    address mint = address(this);    
    
    address genesis = 0x0;

     
    uint256 public tokenPrice = 0.8 ether;

    event Log(uint e);

    event TOKEN(string e);

    bool icoOnPaused = false;

    uint256 startDate;

    uint256 endDate;

    uint currentPhase = 0;

    bool needToBurn = false;

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert();
        }
        _;
    }

    function SMSCoin() public {
        owner = msg.sender;
    }

     
    function safeDiv(uint a, uint b) pure internal returns(uint) {
         
        assert(b > 0);
        uint c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

     
    function safeMul(uint a, uint b) pure internal returns(uint) {
        uint c = a * b;
         
        assert(a == 0 || c / a == b);
        return c;
    }

     
    function safeAdd(uint a, uint b) pure internal returns (uint) {
        assert (a + b >= a);
        return a + b;
    }

    function setBonus(uint8 ratio1, uint8 ratio2, uint8 ratio3, uint8 ratio4) private {
        bonusRatio.ratio1 = ratio1;
        bonusRatio.ratio2 = ratio2;
        bonusRatio.ratio3 = ratio3;
        bonusRatio.ratio4 = ratio4;
    }

    function calcBonus(uint256 sendingSMSToken) view private returns(uint256) {
        uint256 sendingSMSBonus;

         
        if (sendingSMSToken < (10 * UNIT)) {             
            sendingSMSBonus = (sendingSMSToken * bonusRatio.ratio1) / 100;
        } else if (sendingSMSToken < (50 * UNIT)) {      
            sendingSMSBonus = (sendingSMSToken * bonusRatio.ratio2) / 100;
        } else if (sendingSMSToken < (100 * UNIT)) {     
            sendingSMSBonus = (sendingSMSToken * bonusRatio.ratio3) / 100;
        } else {                                         
            sendingSMSBonus = (sendingSMSToken * bonusRatio.ratio4) / 100;
        }

        return sendingSMSBonus;
    }

     
    function () public payable {
        uint256 receivedETH = 0;
        uint256 sendingSMSToken = 0;
        uint256 sendingSMSBonus = 0;
        Log(msg.value);

         
        if (!icoOnPaused && msg.sender != owner) {
            if (now <= endDate) {
                 
                Log(currentPhase);

                 
                receivedETH = (msg.value * UNIT);
                sendingSMSToken = safeDiv(receivedETH, tokenPrice);
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
    }

     
     
     
     
     
     
     
     
     
    function start1BonusPeriod1() external onlyOwner {
         
        if (currentPhase == 0) {
            balances[owner] = tokenSaleLot1;  
            balances[address(this)] = tokenSaleLot1;   
            totalSupply = balances[owner] + balances[address(this)];
            saleCounter = 0;
            limitedSale = tokenSaleLot1;

             
            addAddress(owner);

             
            Transfer(address(this), owner, balances[owner]);

             
            needToBurn = true;
        }

         
        icoOnPaused = false;
        currentPhase = 1;
        startDate = block.timestamp;
        endDate = startDate + 2 days + 9 hours + 59 minutes + 59 seconds;

         
        setBonus(5, 10, 20, 30);
    }

     
     
     
     
     
     
     
     
     
    function start2BonusPeriod2() external onlyOwner {
         
        icoOnPaused = false;
        currentPhase = 2;
        startDate = block.timestamp;
        endDate = startDate + 11 days + 9 hours + 59 minutes + 59 seconds;

         
        setBonus(3, 5, 10, 15);
    }

     
     
     
     
     
     
     
     
     
    function start3BonusPeriod3() external onlyOwner {
         
        icoOnPaused = false;
        currentPhase = 3;
        startDate = block.timestamp;
        endDate = startDate + 51 days;

         
        setBonus(1, 3, 5, 8);
    }

     
     
     
     
    function start4NormalPeriod() external onlyOwner {
         
        icoOnPaused = false;
        currentPhase = 4;
        startDate = block.timestamp;
        endDate = startDate + 31 days;

         
        setBonus(0, 0, 0, 0);
    }

     
     
     
     
     
     
    function start5Phase2020() external onlyOwner {
         
        if (currentPhase == 4) {
             
            if (needToBurn)
                burnSMSProcess();
                
            balances[address(this)] = tokenSaleLot2;
            totalSupply = 3 * totalSupply;
            totalSupply += balances[address(this)];
            saleCounter = 0;
            limitedSale = tokenSaleLot2;

             
            x3Token();  

             
            Transfer(mint, address(this), balances[address(this)]);

             
            needToBurn = true;
        }

         
        icoOnPaused = false;
        currentPhase = 5;
        startDate = block.timestamp;
        endDate = startDate + 7 days;
    }

     
     
     
     
     
     
    function start6Phase2025() external onlyOwner {
         
        if (currentPhase == 5) {
             
            if (needToBurn)
                burnSMSProcess();

            balances[address(this)] = tokenSaleLot3;
            totalSupply = 3 * totalSupply;
            totalSupply += balances[address(this)];
            saleCounter = 0;
            limitedSale = tokenSaleLot3;
            
             
            x3Token();  

             
            Transfer(mint, address(this), balances[address(this)]);

             
            needToBurn = true;
        }
        
         
        icoOnPaused = false;
        currentPhase = 6;
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

     
    function pausePhase() external onlyOwner {
        icoOnPaused = true;
    }

     
    function resumePhase() external onlyOwner {
        icoOnPaused = false;
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

    function saleCounter() public constant returns(uint256 _saleCounter) {
        return saleCounter;
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

     
     
    function setTokenPrice(uint ethRate) external onlyOwner {
        tokenPrice = (ethRate * 10 ** 18) / 10000;  
    }

     
     
    function approve(address _spender, uint256 _amount) public returns(bool success) {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns(uint256 remaining) {
        return allowed[_owner][_spender];
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

     
    function transferTokens(address _to, uint256 _amount, uint256 _bonus) private returns(bool success) {
        if (_amount > 0 && balances[address(this)] >= _amount && balances[address(this)] - _amount >= 0 && soldToken + _amount > soldToken && saleCounter + _amount <= limitedSale && balances[_to] + _amount > balances[_to]) {
            
             
            balances[address(this)] -= _amount;
            soldToken += _amount;
            saleCounter += _amount;
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

     
    function addAddress(address _to) private {
        if (addresses.length > 0) {
            if (userStructs[_to] != _to) {
                userStructs[_to] = _to;
                addresses.push(_to);
            }
        } else {
            userStructs[_to] = _to;
            addresses.push(_to);
        }
    }

     
    function drainETH() external onlyOwner {
        owner.transfer(this.balance);
    }

     
     
     
    function burnSMSProcess() private {
         
        if (currentPhase >= 4) {
             
             
            if (balances[address(this)] > 0) {
                uint toBeBurnedFromContract = balances[address(this)];
                Transfer(address(this), genesis, toBeBurnedFromContract);
                balances[address(this)] = 0;
                totalSupply -= toBeBurnedFromContract;

                 
                if (currentPhase == 4) {
                    if (balances[owner] > soldToken) {
                        uint toBeBurnedFromOwner = balances[owner] - soldToken;
                        Transfer(owner, genesis, toBeBurnedFromOwner);
                        balances[owner] = balances[owner] - toBeBurnedFromOwner;
                        totalSupply -= toBeBurnedFromOwner;
                    }
                }

                 
                needToBurn = false;
            }
        }
    }

     
    function getAddress(uint i) public constant returns(address) {
        return addresses[i];
    }

     
    function getAddressSize() public constant returns(uint) {
        return addresses.length;

    }
}