 

pragma solidity ^0.4.25;

 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) return 0;
        c = a * b;
        assert(c / a == b);
        return c;
    }
     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
     
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}


 
contract SmartMining {
    using SafeMath for uint256;
    
     
     
     
    
    string  constant public name     = "smart-mining.io";  
    string  constant public symbol   = "SMT";              
    uint8   constant public decimals = 18;                 
    uint256 public totalSupply       = 10000;              
    
    struct Member {                                        
        bool    crowdsalePrivateSale;                      
        uint256 crowdsaleMinPurchase;                      
        uint256 balance;                                   
        uint256 unpaid;                                    
    }                                                  
    mapping (address => Member) public members;            
    
    uint16    public memberCount;                          
    address[] public memberIndex;                          
    address   public owner;                                
    address   public withdrawer;                           
    address   public depositor;                            
    
    bool      public crowdsaleOpen;                        
    bool      public crowdsaleFinished;                    
    address   public crowdsaleWallet;                      
    uint256   public crowdsaleCap;                         
    uint256   public crowdsaleRaised;                      
    
    
     
     
     
    
    constructor (uint256 _crowdsaleCapEth, address _crowdsaleWallet, address _teamContract, uint256 _teamShare, address _owner) public {
        require(_crowdsaleCapEth != 0 && _crowdsaleWallet != 0x0 && _teamContract != 0x0 && _teamShare != 0 && _owner != 0x0);
        
         
        owner = _owner;
        emit SetOwner(owner);
        
         
        totalSupply = totalSupply.mul(10 ** uint256(decimals));
        
         
        crowdsaleCap = _crowdsaleCapEth.mul(10 ** 18);
        
         
        withdrawer = msg.sender;
        crowdsaleWallet = _crowdsaleWallet;
        
         
        members[address(this)].balance = totalSupply;
        emit Transfer(0x0, address(this), totalSupply);
        
         
        members[_teamContract].unpaid = 1;
        memberIndex.push(_teamContract);  
        memberCount++;
        
         
        uint256 teamTokens = totalSupply.mul(_teamShare).div(100);
        members[address(this)].balance = members[address(this)].balance.sub(teamTokens);
        members[_teamContract].balance = teamTokens;
        emit Transfer(address(this), _teamContract, teamTokens);
    }
    
    
     
     
     
    
    event SetOwner(address indexed owner);
    event SetDepositor(address indexed depositor);
    event SetWithdrawer(address indexed withdrawer);
    event SetTeamContract(address indexed teamContract);
    event Approve(address indexed member, uint256 crowdsaleMinPurchase, bool privateSale);
    event Participate(address indexed member, uint256 value, uint256 tokens);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event ForwardCrowdsaleFunds(address indexed to, uint256 value);
    event CrowdsaleStarted(bool value);
    event CrowdsaleFinished(bool value);
    event Withdraw(address indexed member, uint256 value);
    event Deposit(address indexed from, uint256 value);
    
    
     
     
     
    
    function approve (address _beneficiary, uint256 _ethMinPurchase, bool _privateSale) external {
        require(msg.sender == owner || msg.sender == withdrawer, "Only SmartMining-API and contract owner allowed to approve.");
        require(crowdsaleFinished == false, "No new approvals after crowdsale finished.");
        require(_beneficiary != 0x0);
        
        if( members[_beneficiary].unpaid == 1 ) {
            members[_beneficiary].crowdsaleMinPurchase = _ethMinPurchase.mul(10 ** 18);
            members[_beneficiary].crowdsalePrivateSale = _privateSale;
        } else {
            members[_beneficiary].unpaid = 1;
            members[_beneficiary].crowdsaleMinPurchase = _ethMinPurchase.mul(10 ** 18);
            members[_beneficiary].crowdsalePrivateSale = _privateSale;
            
            memberIndex.push(_beneficiary);
            memberCount++;
        }
        
        emit Approve(_beneficiary, members[_beneficiary].crowdsaleMinPurchase, _privateSale);
    }
    
    
     
     
     
    
    modifier onlyOwner () {
        require(msg.sender == owner);
        _;
    }
    
    function setTeamContract (address _newTeamContract) external onlyOwner {
        require(_newTeamContract != 0x0 && _newTeamContract != memberIndex[0]);
        
         
        members[_newTeamContract] = members[memberIndex[0]];
        delete members[memberIndex[0]];
        
         
        emit SetTeamContract(_newTeamContract);
        emit Transfer(memberIndex[0], _newTeamContract, members[_newTeamContract].balance);
        
         
        memberIndex[0] = _newTeamContract;
    }
    
    function setOwner (address _newOwner) external onlyOwner {
        if( _newOwner != 0x0 ) { owner = _newOwner; } else { owner = msg.sender; }
        emit SetOwner(owner);
    }
    
    function setDepositor (address _newDepositor) external onlyOwner {
        depositor = _newDepositor;
        emit SetDepositor(_newDepositor);
    }
    
    function setWithdrawer (address _newWithdrawer) external onlyOwner {
        withdrawer = _newWithdrawer;
        emit SetWithdrawer(_newWithdrawer);
    }
    
    function startCrowdsale () external onlyOwner {
        require(crowdsaleFinished == false, "Crowdsale can only be started once.");
        
        crowdsaleOpen = true;
        emit CrowdsaleStarted(true);
    }
    
    function cleanupMember (uint256 _memberIndex) external onlyOwner {
        require(members[memberIndex[_memberIndex]].unpaid == 1, "Not a member.");
        require(members[memberIndex[_memberIndex]].balance == 0, "Only members without participation can be deleted.");
        
         
        delete members[memberIndex[_memberIndex]];
        memberIndex[_memberIndex] = memberIndex[memberIndex.length-1];
        memberIndex.length--;
        memberCount--;
    }
    
    
     
     
     
    
    function () external payable {
        require(crowdsaleOpen || members[msg.sender].crowdsalePrivateSale || crowdsaleFinished, "smart-mining.io crowdsale not started yet.");
        
        if(crowdsaleFinished)
            deposit();
        if(crowdsaleOpen || members[msg.sender].crowdsalePrivateSale)
            participate();
    }
    
    function deposit () public payable {
         
        require(crowdsaleFinished, "Deposits only possible after crowdsale finished.");
        require(msg.sender == depositor, "Only 'depositor' allowed to deposit.");
        require(msg.value >= 10**9, "Minimum deposit 1 gwei.");
        
         
        for (uint i=0; i<memberIndex.length; i++) {
            members[memberIndex[i]].unpaid = 
                 
                members[memberIndex[i]].unpaid.add(
                     
                    members[memberIndex[i]].balance.mul(msg.value).div(totalSupply)
                );
        }
        
         
        emit Deposit(msg.sender, msg.value);
    }
    
    function participate () public payable {
         
        require(members[msg.sender].unpaid == 1, "Only whitelisted members are allowed to participate!");
        require(crowdsaleOpen || members[msg.sender].crowdsalePrivateSale, "Crowdsale is not open.");
        require(msg.value != 0, "No Ether attached to this buy order.");
        require(members[msg.sender].crowdsaleMinPurchase == 0 || msg.value >= members[msg.sender].crowdsaleMinPurchase,
            "Send at least your whitelisted crowdsaleMinPurchase Ether amount!");
            
         
        uint256 tokens = crowdsaleCalcTokenAmount(msg.value);
        require(members[address(this)].balance >= tokens, "There are not enaugh Tokens left for this order.");
        emit Participate(msg.sender, msg.value, tokens);
        
         
        members[msg.sender].crowdsaleMinPurchase = 0;
        
         
        members[address(this)].balance = members[address(this)].balance.sub(tokens);
        members[msg.sender].balance = members[msg.sender].balance.add(tokens);
        emit Transfer(address(this), msg.sender, tokens);
        
         
        crowdsaleRaised = crowdsaleRaised.add(msg.value);
        if(members[address(this)].balance == 0) {
             
            crowdsaleOpen = false;
            crowdsaleFinished = true;
            emit CrowdsaleFinished(true);
        }
        
         
        emit ForwardCrowdsaleFunds(crowdsaleWallet, msg.value);
        crowdsaleWallet.transfer(msg.value);
    }
    
    function crowdsaleCalcTokenAmount (uint256 _weiAmount) public view returns (uint256) {
         
        return 
             
            _weiAmount
            .mul(totalSupply)
            .div(crowdsaleCap)
            .mul( totalSupply.sub(members[memberIndex[0]].balance) )
            .div(totalSupply);
    }
    
    function withdrawOf              (address _beneficiary) external                      { _withdraw(_beneficiary); }
    function withdraw                ()                     external                      { _withdraw(msg.sender); }
    function balanceOf               (address _beneficiary) public view returns (uint256) { return members[_beneficiary].balance; }
    function unpaidOf                (address _beneficiary) public view returns (uint256) { return members[_beneficiary].unpaid.sub(1); }
    function crowdsaleIsMemberOf     (address _beneficiary) public view returns (bool)    { return members[_beneficiary].unpaid >= 1; }
    function crowdsaleRemainingWei   ()                     public view returns (uint256) { return crowdsaleCap.sub(crowdsaleRaised); }
    function crowdsaleRemainingToken ()                     public view returns (uint256) { return members[address(this)].balance; }
    function crowdsalePercentOfTotalSupply ()               public view returns (uint256) { return totalSupply.sub(members[memberIndex[0]].balance).mul(100).div(totalSupply); }
    
    
     
     
     
    
    function _withdraw (address _beneficiary) private {
         
        if(msg.sender != _beneficiary) {
            require(msg.sender == owner || msg.sender == withdrawer, "Only 'owner' and 'withdrawer' can withdraw for other members.");
        }
        require(members[_beneficiary].unpaid >= 1, "Not a member account.");
        require(members[_beneficiary].unpaid > 1, "No unpaid balance on account.");
        
         
        uint256 unpaid = members[_beneficiary].unpaid.sub(1);
        members[_beneficiary].unpaid = 1;
        
         
        emit Withdraw(_beneficiary, unpaid);
        
         
        if(_beneficiary != memberIndex[0]) {
             
            _beneficiary.transfer(unpaid);
        } else {
             
            require( _beneficiary.call.gas(230000).value(unpaid)() );
        }
    }
    
    
}