 

pragma solidity ^0.4.2;

contract Token {
     
    string public standard;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public _totalSupply;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed from, address indexed spender, uint256 value);

     
    function Token(uint256 initialSupply, string _standard, string _name, string _symbol, uint8 _decimals) {
        _totalSupply = initialSupply;
        balanceOf[this] = initialSupply;
        standard = _standard;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

     
    function totalSupply() constant returns(uint256 supply) {
        return _totalSupply;
    }

     
    function transferInternal(address _from, address _to, uint256 _value) internal returns (bool success) {
        require(balanceOf[_from] >= _value);

         
        require(balanceOf[_to] + _value >= balanceOf[_to]);

        balanceOf[_from] -= _value;

        balanceOf[_to] += _value;

        Transfer(_from, _to, _value);

        return true;
    }

     
    function approve(address _spender, uint256 _value) returns (bool success) {
        allowance[msg.sender][_spender] = _value;

        return true;
    }

     
    function transferFromInternal(address _from, address _to, uint256 _value) internal returns (bool success) {
        require(_value >= allowance[_from][msg.sender]);    

        allowance[_from][msg.sender] -= _value;

        return transferInternal(_from, _to, _value);
    }
}

contract ICO {
    uint256 public PRE_ICO_SINCE = 1500303600;                      
    uint256 public PRE_ICO_TILL = 1500476400;                       
    uint256 public constant PRE_ICO_BONUS_RATE = 70;
    uint256 public constant PRE_ICO_SLGN_LESS = 5000 ether;                  

    uint256 public ICO_SINCE = 1500994800;                          
    uint256 public ICO_TILL = 1502809200;                           
    uint256 public constant ICO_BONUS1_SLGN_LESS = 20000 ether;                 
    uint256 public constant ICO_BONUS1_RATE = 30;                            
    uint256 public constant ICO_BONUS2_SLGN_LESS = 50000 ether;                 
    uint256 public constant ICO_BONUS2_RATE = 15;  

    uint256 public totalSoldSlogns;

     
    event BonusEarned(address target, uint256 bonus);

     
    function calculateBonus(uint8 icoStep, uint256 totalSoldSlogns, uint256 soldSlogns) returns (uint256) {
        if(icoStep == 1) {
             
            return soldSlogns / 100 * PRE_ICO_BONUS_RATE;
        }
        else if(icoStep == 2) {
             
            if(totalSoldSlogns > ICO_BONUS1_SLGN_LESS + ICO_BONUS2_SLGN_LESS) {
                return 0;
            }

            uint256 availableForBonus1 = ICO_BONUS1_SLGN_LESS - totalSoldSlogns;

            uint256 tmp = soldSlogns;
            uint256 bonus = 0;

            uint256 tokensForBonus1 = 0;

            if(availableForBonus1 > 0 && availableForBonus1 <= ICO_BONUS1_SLGN_LESS) {
                tokensForBonus1 = tmp > availableForBonus1 ? availableForBonus1 : tmp;

                bonus += tokensForBonus1 / 100 * ICO_BONUS1_RATE;
                tmp -= tokensForBonus1;
            }

            uint256 availableForBonus2 = (ICO_BONUS2_SLGN_LESS + ICO_BONUS1_SLGN_LESS) - totalSoldSlogns - tokensForBonus1;

            uint256 tokensForBonus2 = 0;

            if(availableForBonus2 > 0 && availableForBonus2 <= ICO_BONUS2_SLGN_LESS) {
                tokensForBonus2 = tmp > availableForBonus2 ? availableForBonus2 : tmp;

                bonus += tokensForBonus2 / 100 * ICO_BONUS2_RATE;
                tmp -= tokensForBonus2;
            }

            return bonus;
        }

        return 0;
    }
}

contract EscrowICO is Token, ICO {
    uint256 public constant MIN_PRE_ICO_SLOGN_COLLECTED = 1000 ether;        
    uint256 public constant MIN_ICO_SLOGN_COLLECTED = 1000 ether;           

    bool public isTransactionsAllowed;

    uint256 public totalSoldSlogns;

    mapping (address => uint256) public preIcoEthers;
    mapping (address => uint256) public icoEthers;

    event RefundEth(address indexed owner, uint256 value);
    event IcoFinished();

    function EscrowICO() {
        isTransactionsAllowed = false;
    }

    function getIcoStep(uint256 time) returns (uint8 step) {
        if(time >=  PRE_ICO_SINCE && time <= PRE_ICO_TILL) {
            return 1;
        }
        else if(time >= ICO_SINCE && time <= ICO_TILL) {
             
            if(totalSoldSlogns >= MIN_PRE_ICO_SLOGN_COLLECTED) {
                return 2;
            }
        }

        return 0;
    }

     
    function icoFinishInternal(uint256 time) internal returns (bool) {
        if(time <= ICO_TILL) {
            return false;
        }

        if(totalSoldSlogns >= MIN_ICO_SLOGN_COLLECTED) {
             

            _totalSupply = _totalSupply - balanceOf[this];

            balanceOf[this] = 0;

             
            isTransactionsAllowed = true;

            IcoFinished();

            return true;
        }

        return false;
    }

     
    function refundInternal(uint256 time) internal returns (bool) {
        if(time <= PRE_ICO_TILL) {
            return false;
        }

        if(totalSoldSlogns >= MIN_PRE_ICO_SLOGN_COLLECTED) {
            return false;
        }

        uint256 transferedEthers;

        transferedEthers = preIcoEthers[msg.sender];

        if(transferedEthers > 0) {
            preIcoEthers[msg.sender] = 0;

            balanceOf[msg.sender] = 0;

            msg.sender.transfer(transferedEthers);

            RefundEth(msg.sender, transferedEthers);

            return true;
        }

        return false;
    }
}

contract SlognToken is Token, EscrowICO {
    string public constant STANDARD = 'Slogn v0.1';
    string public constant NAME = 'SLOGN';
    string public constant SYMBOL = 'SLGN';
    uint8 public constant PRECISION = 14;

    uint256 public constant TOTAL_SUPPLY = 800000 ether;  

    uint256 public constant CORE_TEAM_TOKENS = TOTAL_SUPPLY / 100 * 15;        
    uint256 public constant ADVISORY_BOARD_TOKENS = TOTAL_SUPPLY / 1000 * 15;        
    uint256 public constant OPENSOURCE_TOKENS = TOTAL_SUPPLY / 1000 * 75;      
    uint256 public constant RESERVE_TOKENS = TOTAL_SUPPLY / 100 * 5;           
    uint256 public constant BOUNTY_TOKENS = TOTAL_SUPPLY / 100;                

    address public advisoryBoardFundManager;
    address public opensourceFundManager;
    address public reserveFundManager;
    address public bountyFundManager;
    address public ethFundManager;
    address public owner;

     
    event BonusEarned(address target, uint256 bonus);

     
    modifier onlyOwner() {
        require(owner == msg.sender);

        _;
    }

     
    function SlognToken(
    address [] coreTeam,
    address _advisoryBoardFundManager,
    address _opensourceFundManager,
    address _reserveFundManager,
    address _bountyFundManager,
    address _ethFundManager
    )
    Token (TOTAL_SUPPLY, STANDARD, NAME, SYMBOL, PRECISION)
    EscrowICO()
    {
        owner = msg.sender;

        advisoryBoardFundManager = _advisoryBoardFundManager;
        opensourceFundManager = _opensourceFundManager;
        reserveFundManager = _reserveFundManager;
        bountyFundManager = _bountyFundManager;
        ethFundManager = _ethFundManager;

         
        uint256 tokensPerMember = CORE_TEAM_TOKENS / coreTeam.length;

        for(uint8 i = 0; i < coreTeam.length; i++) {
            transferInternal(this, coreTeam[i], tokensPerMember);
        }

         
        transferInternal(this, advisoryBoardFundManager, ADVISORY_BOARD_TOKENS);

         
        transferInternal(this, opensourceFundManager, OPENSOURCE_TOKENS);

         
        transferInternal(this, reserveFundManager, RESERVE_TOKENS);

         
        transferInternal(this, bountyFundManager, BOUNTY_TOKENS);
    }

    function buyFor(address _user, uint256 ethers, uint time) internal returns (bool success) {
        require(ethers > 0);

        uint8 icoStep = getIcoStep(time);

        require(icoStep == 1 || icoStep == 2);

         
        if(icoStep == 1 && (totalSoldSlogns + ethers) > 5000 ether) {
            throw;
        }

        uint256 slognAmount = ethers;  

        uint256 bonus = calculateBonus(icoStep, totalSoldSlogns, slognAmount);

         
        require(balanceOf[this] >= slognAmount + bonus);

        if(bonus > 0) {
            BonusEarned(_user, bonus);
        }

        transferInternal(this, _user, slognAmount + bonus);

        totalSoldSlogns += slognAmount;

        if(icoStep == 1) {
            preIcoEthers[_user] += ethers;       
        }
        if(icoStep == 2) {
            icoEthers[_user] += ethers;       
        }

        return true;
    }

     
    function buy() payable {
        buyFor(msg.sender, msg.value, block.timestamp);
    }

     
    function transferEther(address to, uint256 value) returns (bool success) {
        if(msg.sender != ethFundManager) {
            return false;
        }

        if(totalSoldSlogns < MIN_PRE_ICO_SLOGN_COLLECTED) {
            return false;
        }

        if(this.balance < value) {
            return false;
        }

        to.transfer(value);

        return true;
    }

     
    function transfer(address _to, uint256 _value) returns (bool success) {
        if(isTransactionsAllowed == false) {
            if(msg.sender != bountyFundManager) {
                return false;
            }
        }

        return transferInternal(msg.sender, _to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if(isTransactionsAllowed == false) {
            if(_from != bountyFundManager) {
                return false;
            }
        }

        return transferFromInternal(_from, _to, _value);
    }

    function refund() returns (bool) {
        return refundInternal(block.timestamp);
    }

    function icoFinish() returns (bool) {
        return icoFinishInternal(block.timestamp);
    }

    function setPreIcoDates(uint256 since, uint256 till) onlyOwner {
        PRE_ICO_SINCE = since;
        PRE_ICO_TILL = till;
    }

    function setIcoDates(uint256 since, uint256 till) onlyOwner {
        ICO_SINCE = since;
        ICO_TILL = till;
    }

    function setTransactionsAllowed(bool enabled) onlyOwner {
        isTransactionsAllowed = enabled;
    }

    function () payable {
        throw;
    }
}