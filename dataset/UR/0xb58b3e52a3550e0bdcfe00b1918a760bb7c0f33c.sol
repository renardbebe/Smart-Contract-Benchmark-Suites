 

pragma solidity ^ 0.4.21;

 
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns(uint256) {
        assert(b > 0);
        uint256 c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


 
contract ERC20 {
    function balanceOf(address _owner) public constant returns(uint256);
    function transfer(address _to, uint256 _value) public returns(bool);
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool);
    function approve(address _spender, uint256 _value) public returns(bool);
    function allowance(address _owner, address _spender) public constant returns(uint256);
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


 
contract CretToken is ERC20 {
    using SafeMath for uint256;
    string public name = "CRET TOKEN";
    string public symbol = "CRET";
    uint256 public decimals = 18;
    uint256 public totalSupply = 0;
    uint256 public riskTokens;
    uint256 public bountyTokens;
    uint256 public advisersTokens;
    uint256 public reserveTokens;
    uint256 public constant reserveTokensLimit = 5000000 * 1e18;  
    uint256 public lastBountyStatus;
    address public teamOneYearFrozen;
    address public teamHalfYearFrozen;
    uint256 public timeStamp;



     
    address public owner;
    event Burn(address indexed from, uint256 value);

     
    bool public tokensAreFrozen = true;

     
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    
    
    constructor (address _owner, address _team, address _team2) public {
        owner = _owner;
        timeStamp = now;
        teamOneYearFrozen = _team;
        teamHalfYearFrozen = _team2;

    }
    
    

    
    function mintTokens(address _investor, uint256 _value) external onlyOwner {
        require(_value > 0);
        balances[_investor] = balances[_investor].add(_value);
        totalSupply = totalSupply.add(_value);
        emit Transfer(0x0, _investor, _value);
    }
    
    
    function mintRiskTokens(address _investor, uint256 _value) external onlyOwner {
        balances[_investor] = balances[_investor].add(_value);
        totalSupply = totalSupply.add(_value);
        riskTokens = riskTokens.add(_value);
        emit Transfer(0x0, _investor, _value);
    }
    
    
    function mintReserveTokens(address _investor, uint256 _value) external onlyOwner {
        require(reserveTokens.add(_value) <= reserveTokensLimit);
        balances[_investor] = balances[_investor].add(_value);
        totalSupply = totalSupply.add(_value);
        reserveTokens = reserveTokens.add(_value);
        emit Transfer(0x0, _investor, _value);
    }
    
    
    function mintAdvisersTokens(address _investor, uint256 _value) external onlyOwner {
        balances[_investor] = balances[_investor].add(_value);
        totalSupply = totalSupply.add(_value);
        advisersTokens = advisersTokens.add(_value);
        emit Transfer(0x0, _investor, _value);
    }
    

    function mintBountyTokens(address[] _dests, uint256 _value) external onlyOwner {
        lastBountyStatus = 0;
        for (uint256 i = 0;i < _dests.length; i++) {
        address tmp = _dests[i];
        balances[tmp] = balances[tmp].add(_value);
        totalSupply = totalSupply.add(_value);
        bountyTokens = bountyTokens.add(_value);
        lastBountyStatus++;
        emit Transfer(0x0, tmp, _value);
        }
    }
    


    
    function defrostTokens() external onlyOwner {
      tokensAreFrozen = false;
    }

    
    function frostTokens() external onlyOwner {
      tokensAreFrozen = true;
    }

    
    function burnTokens(address _investor, uint256 _value) external onlyOwner {
        require(balances[_investor] > 0);
        balances[_investor] = balances[_investor].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(_investor, _value);
    }

    
    function balanceOf(address _owner) public constant returns(uint256) {
      return balances[_owner];
    }

    
    function transfer(address _to, uint256 _amount) public returns(bool) {
        require(!tokensAreFrozen);
        if(now < (timeStamp + 425 days)){                
            require(msg.sender != teamOneYearFrozen);
        } 
        if(now < (timeStamp + 240 days)){        	 
            require(msg.sender != teamHalfYearFrozen);
        }

        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }

    
    function transferFrom(address _from, address _to, uint256 _amount) public returns(bool) {
        require(!tokensAreFrozen);
        require(_amount <= allowed[_from][msg.sender]);
        require(_amount <= balances[_from]);
        if(now < (timeStamp + 425 days)){                
            require(msg.sender != teamOneYearFrozen);
            require(_from != teamOneYearFrozen);
        }
        if(now < (timeStamp + 240 days)){        	 
            require(msg.sender != teamHalfYearFrozen);
            require(_from != teamHalfYearFrozen);
        }

        balances[_from] = balances[_from].sub(_amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(_from, _to, _amount);
        return true;
    }

    
    function approve(address _spender, uint256 _amount) public returns(bool) {
        require((_amount == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    
    function allowance(address _owner, address _spender) public constant returns(uint256) {
        return allowed[_owner][_spender];
    }
}


contract CretICO {
    using SafeMath for uint256;
    
    address public TeamFund;  
    address public TeamFund2;  
    address public Companion1;
    address public Companion2;
    address public Manager;  
    address internal addressCompanion1;
    address internal addressCompanion2;
    CretToken public CRET;
    
     
    constructor (
        address _TeamFund,
        address _TeamFund2,
        address _Companion1,
        address _Companion2,
        address _Manager
    )
        public {
        TeamFund = _TeamFund;
        TeamFund2 = _TeamFund2;
        Manager = _Manager;
        Companion1 = _Companion1;
        Companion2 = _Companion2;
        statusICO = StatusICO.Created;
        CRET = new CretToken(this, _TeamFund, _TeamFund2);
    }
    
 
    

     
    uint256 public Rate_Eth = 700;  
    uint256 public Tokens_Per_Dollar = 10;  
    uint256 public Token_Price = Tokens_Per_Dollar.mul(Rate_Eth);  
    uint256 constant teamPart = 75;  
    uint256 constant advisersPart = 30;  
    uint256 constant riskPart = 10;  
    uint256 constant airdropPart = 10;  
    uint256 constant SOFT_CAP = 30000000 * 1e18;  
    uint256 constant HARD_CAP = 450000000 * 1e18;  
    uint256 internal constant maxDeposit = 5000000 * 1e18;
    uint256 internal constant bonusRange1 = 30000000 * 1e18;
    uint256 internal constant bonusRange2 = 100000000 * 1e18;
    uint256 internal constant bonusRange3 = 200000000 * 1e18;
    uint256 internal constant bonusRange4 = 300000000 * 1e18;
    uint256 public soldTotal;   
    bool public canIBuy = false;
    bool public canIWithdraw = false;


    
    

     
    enum StatusICO {
        Created,
        PreIco,
        PreIcoFinished,
        Ico,
        IcoFinished
    }
    
    
    StatusICO statusICO;

     

    mapping(address => uint256) public icoInvestments;  
    mapping(address => bool) public returnStatus;  
    mapping(address => uint256) public tokensIco;  
    mapping(address => uint256) public tokensIcoInOtherCrypto;  
    mapping(address => uint256) public pureBalance;  
    mapping(address => bool) public kyc;   

     
    event LogStartPreIco();
    event LogFinishPreICO();
    event LogStartIco();
    event LogFinishICO();
    event LogBuyForInvestor(address investor, uint256 value);
    event LogReturnEth(address investor, uint256 eth);
    event LogReturnOtherCrypto(address investor);

     
     
    modifier managerOnly {
        require(msg.sender == Manager);
        _;
    }
    
     
    modifier companionsOnly {
        require(msg.sender == Companion1 || msg.sender == Companion2);
        _;
    }


     
    function passKYC(address _investor) external managerOnly {
        kyc[_investor] = true;
    }

     
    function giveRiskToken(address _investor, uint256 _value) external managerOnly {
        require(_value > 0);
        uint256 rt = CRET.riskTokens();
        uint256 decvalue = _value.mul(1 ether);
        require(rt.add(decvalue) <= soldTotal.div(1000).mul(riskPart));
        CRET.mintRiskTokens(_investor, decvalue);
    }
    
    function giveAdvisers(address _investor, uint256 _value) external managerOnly {
        require(_value > 0);
        uint256 at = CRET.advisersTokens();
        uint256 decvalue = _value.mul(1 ether);
        require(at.add(decvalue) <= soldTotal.div(1000).mul(advisersPart));  
        CRET.mintAdvisersTokens(_investor, decvalue);
    }
    
    function giveReserveFund(address _investor, uint256 _value) external managerOnly {
        require(_value > 0);
        uint256 decvalue = _value.mul(1 ether);
        CRET.mintReserveTokens(_investor, decvalue);
    }
    
    function giveBounty(address[] dests, uint256 _value) external managerOnly {
        require(_value > 0);
        uint256 bt = CRET.bountyTokens();
        uint256 decvalue = _value.mul(1 ether);
        uint256 wantToMint = dests.length.mul(decvalue);
        require(bt.add(wantToMint) <= soldTotal.div(1000).mul(airdropPart)); 
        CRET.mintBountyTokens(dests, decvalue);

    }
    
   
    function pureBalance(address _owner) public constant returns(uint256) {
      return pureBalance[_owner];
    }
    
    
    function currentStage() public view returns (string) {
        if(statusICO == StatusICO.Created){return "Created";}
        else if(statusICO == StatusICO.PreIco){return  "PreIco";}
        else if(statusICO == StatusICO.PreIcoFinished){return "PreIcoFinished";}
        else if(statusICO == StatusICO.Ico){return "Ico";}
        else if(statusICO == StatusICO.IcoFinished){return "IcoFinished";}
    }

    
    function setRate(uint256 _RateEth) external managerOnly {
        Rate_Eth = _RateEth;
        Token_Price = Tokens_Per_Dollar.mul(Rate_Eth);
    }

    
    function startPreIco() external managerOnly {
        require(statusICO == StatusICO.Created); 
        statusICO = StatusICO.PreIco;
        emit LogStartPreIco();
    }
    
     
    function finishPreIco() external managerOnly {
        require(statusICO == StatusICO.PreIco);
        statusICO = StatusICO.PreIcoFinished;
        emit LogFinishPreICO();
    }

 
 

    
    
    function setIco() external managerOnly {
        require(statusICO == StatusICO.PreIcoFinished);
        statusICO = StatusICO.Ico;
        canIBuy = true;
        emit LogStartIco();
    }


    
    function finishIco() external managerOnly {
        require(statusICO == StatusICO.Ico);
        
        uint256 teamTokens = soldTotal.div(1000).mul(teamPart);
        CRET.mintTokens(TeamFund, teamTokens);
        CRET.mintTokens(TeamFund2, teamTokens);
        statusICO = StatusICO.IcoFinished;
        canIBuy = false;
        if(soldTotal < SOFT_CAP){canIWithdraw = true;}
        emit LogFinishICO();
    }


    
    function enableTokensTransfer() external managerOnly {
        CRET.defrostTokens();
    }

     
    function disableTokensTransfer() external managerOnly {
        require(statusICO != StatusICO.IcoFinished);
        CRET.frostTokens();
    }

    
    function() external payable {
        require(canIBuy);
        require(kyc[msg.sender]);
        require(msg.value > 0);
        require(msg.value.mul(Token_Price) <= maxDeposit);
        require(pureBalance[msg.sender].add(msg.value.mul(Token_Price)) <= maxDeposit);
        createTokens(msg.sender, msg.value.mul(Token_Price), msg.value);
    }
    
   
    
    function buyToken() external payable {
        require(canIBuy);
        require(kyc[msg.sender]);
        require(msg.value > 0);
        require(msg.value.mul(Token_Price) <= maxDeposit);
        require(pureBalance[msg.sender].add(msg.value.mul(Token_Price)) <= maxDeposit);
        createTokens(msg.sender, msg.value.mul(Token_Price), msg.value);
    }
    
    
    function buyPreIco() external payable {
        require(msg.value.mul(Token_Price) <= maxDeposit);
        require(kyc[msg.sender]);
        require(statusICO == StatusICO.PreIco);
        require(pureBalance[msg.sender].add(msg.value.mul(Token_Price)) <= maxDeposit);
        createTokens(msg.sender, msg.value.mul(Token_Price), msg.value);
    }



    function buyForInvestor(address _investor, uint256 _value) external managerOnly {
        uint256 decvalue = _value.mul(1 ether);
        require(_value > 0);
        require(kyc[_investor]);
        require(pureBalance[_investor].add(decvalue) <= maxDeposit);
        require(decvalue <= maxDeposit);
        require(statusICO != StatusICO.IcoFinished);
        require(statusICO != StatusICO.PreIcoFinished);
        require(statusICO != StatusICO.Created);
        require(soldTotal.add(decvalue) <= HARD_CAP);
        uint256 bonus = getBonus(decvalue);
        uint256 total = decvalue.add(bonus);
        tokensIcoInOtherCrypto[_investor] = tokensIcoInOtherCrypto[_investor].add(total);
        soldTotal = soldTotal.add(decvalue);
        pureBalance[_investor] = pureBalance[_investor].add(decvalue);
        
        CRET.mintTokens(_investor, total);
        emit LogBuyForInvestor(_investor, _value);
    }
    


    function createTokens(address _investor, uint256 _value, uint256 _ethValue) internal {
        require(_value > 0);
        require(soldTotal.add(_value) <= HARD_CAP);
        uint256 bonus = getBonus(_value);
        uint256 total = _value.add(bonus);
        tokensIco[_investor] = tokensIco[_investor].add(total);
        icoInvestments[_investor] = icoInvestments[_investor].add(_ethValue);
        soldTotal = soldTotal.add(_value);
        pureBalance[_investor] = pureBalance[_investor].add(_value);
      
        CRET.mintTokens(_investor, total);
    }



    
    function getBonus(uint256 _value) public view returns(uint256) {
        uint256 bonus = 0;
        if (soldTotal <= bonusRange1) {
            if(soldTotal.add(_value) <= bonusRange1){
                bonus = _value.mul(500).div(1000);
            } else {
                uint256 part1 = (soldTotal.add(_value)).sub(bonusRange1);
                uint256 part2 = _value.sub(part1);
                uint256 bonusPart1 = part1.mul(300).div(1000);
                uint256 bonusPart2 = part2.mul(500).div(1000);
                bonus = bonusPart1.add(bonusPart2);
            }
                                
        } else if (soldTotal > bonusRange1 && soldTotal <= bonusRange2) {
            if(soldTotal.add(_value) <= bonusRange2){
                bonus = _value.mul(300).div(1000);
            } else {
                part1 = (soldTotal.add(_value)).sub(bonusRange2);
                part2 = _value.sub(part1);
                bonusPart1 = part1.mul(200).div(1000);
                bonusPart2 = part2.mul(300).div(1000);
                bonus = bonusPart1.add(bonusPart2);
            }
        } else if (soldTotal > bonusRange2 && soldTotal <= bonusRange3) {
            if(soldTotal.add(_value) <= bonusRange3){
                bonus = _value.mul(200).div(1000);
            } else {
                part1 = (soldTotal.add(_value)).sub(bonusRange3);
                part2 = _value.sub(part1);
                bonusPart1 = part1.mul(100).div(1000);
                bonusPart2 = part2.mul(200).div(1000);
                bonus = bonusPart1.add(bonusPart2);
            }
        } else if (soldTotal > bonusRange3 && soldTotal <= bonusRange4) {
            if(soldTotal.add(_value) <= bonusRange4){
                bonus = _value.mul(100).div(1000);
            } else {
                part1 = (soldTotal.add(_value)).sub(bonusRange4);
                part2 = _value.sub(part1);
                bonusPart1 = 0;
                bonusPart2 = part2.mul(100).div(1000);
                bonus = bonusPart1.add(bonusPart2);
            }
        } 
        return bonus;
    }
    
    
    

    
    function returnEther() public {
        require(canIWithdraw);
        require(!returnStatus[msg.sender]);
        require(icoInvestments[msg.sender] > 0);
        uint256 eth = 0;
        uint256 tokens = 0;
        eth = icoInvestments[msg.sender];
        tokens = tokensIco[msg.sender];
        icoInvestments[msg.sender] = 0;
        tokensIco[msg.sender] = 0;
        pureBalance[msg.sender] = 0;
        returnStatus[msg.sender] = true;

        CRET.burnTokens(msg.sender, tokens);
        msg.sender.transfer(eth);
        emit LogReturnEth(msg.sender, eth);
    }

    
    function returnOtherCrypto(address _investor)external managerOnly {
        require(canIWithdraw);
        require(tokensIcoInOtherCrypto[_investor] > 0);
        uint256 tokens = 0;
        tokens = tokensIcoInOtherCrypto[_investor];
        tokensIcoInOtherCrypto[_investor] = 0;
        pureBalance[_investor] = 0;

        CRET.burnTokens(_investor, tokens);
        emit LogReturnOtherCrypto(_investor);
    }
    
    
     
    function consensusAddress(address _investor) external companionsOnly {
        if(msg.sender == Companion1) {
            addressCompanion1 = _investor;
        } else {
            addressCompanion2 = _investor;
        }
    }
    
    
    
   

    
    function takeInvestments() external companionsOnly {
        require(addressCompanion1 != 0x0 && addressCompanion2 != 0x0);
        require(addressCompanion1 == addressCompanion2);
        require(soldTotal >= SOFT_CAP);
        addressCompanion1.transfer(address(this).balance);
        CRET.defrostTokens();
        }
        
    }


 