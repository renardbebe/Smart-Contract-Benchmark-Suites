 

pragma solidity ^0.4.15;
 
contract Utils {
     
    function Utils() {
    }

     
    modifier validAddress(address _address) {
        require(_address != 0x0);
        _;
    }

     
    modifier notThis(address _address) {
        require(_address != address(this));
        _;
    }

     

     
    function safeAdd(uint256 _x, uint256 _y) internal returns (uint256) {
        uint256 z = _x + _y;
        assert(z >= _x);
        return z;
    }

     
    function safeSub(uint256 _x, uint256 _y) internal returns (uint256) {
        assert(_x >= _y);
        return _x - _y;
    }

     
    function safeMul(uint256 _x, uint256 _y) internal returns (uint256) {
        uint256 z = _x * _y;
        assert(_x == 0 || z / _x == _y);
        return z;
    }
}

 
contract IERC20Token {
     
    function name() public constant returns (string) { name; }
    function symbol() public constant returns (string) { symbol; }
    function decimals() public constant returns (uint8) { decimals; }
    function totalSupply() public constant returns (uint256) { totalSupply; }
    function balanceOf(address _owner) public constant returns (uint256 balance) { _owner; balance; }
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) { _owner; _spender; remaining; }

    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
}


 
contract ERC20Token is IERC20Token, Utils {
    string public standard = "Token 0.1";
    string public name = "";
    string public symbol = "";
    uint8 public decimals = 0;
    uint256 public totalSupply = 0;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

     
    function ERC20Token(string _name, string _symbol, uint8 _decimals) {
        require(bytes(_name).length > 0 && bytes(_symbol).length > 0);  

        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

     
    function transfer(address _to, uint256 _value)
        public
        validAddress(_to)
        returns (bool success)
    {
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], _value);
        balanceOf[_to] = safeAdd(balanceOf[_to], _value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value)
        public
        validAddress(_from)
        validAddress(_to)
        returns (bool success)
    {
        allowance[_from][msg.sender] = safeSub(allowance[_from][msg.sender], _value);
        balanceOf[_from] = safeSub(balanceOf[_from], _value);
        balanceOf[_to] = safeAdd(balanceOf[_to], _value);
        Transfer(_from, _to, _value);
        return true;
    }




     
    function approve(address _spender, uint256 _value)
        public
        validAddress(_spender)
        returns (bool success)
    {
         
        require(_value == 0 || allowance[msg.sender][_spender] == 0);

        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
}

 
contract IOwned {
     
    function owner() public constant returns (address) { owner; }

    function transferOwnership(address _newOwner) public;
    function acceptOwnership() public;
}

 
contract Owned is IOwned {
    address public owner;
    address public newOwner;

    event OwnerUpdate(address _prevOwner, address _newOwner);

     
    function Owned() {
        owner = msg.sender;
    }

     
    modifier ownerOnly {
        assert(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address _newOwner) public ownerOnly {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

     
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = 0x0;
    }
}

 
contract ITokenHolder is IOwned {
    function withdrawTokens(IERC20Token _token, address _to, uint256 _amount) public;
}


contract TokenHolder is ITokenHolder, Owned, Utils {
     
    function TokenHolder() {
    }

     
    function withdrawTokens(IERC20Token _token, address _to, uint256 _amount)
        public
        ownerOnly
        validAddress(_token)
        validAddress(_to)
        notThis(_to)
    {
        assert(_token.transfer(_to, _amount));
    }
}


contract CLRSToken is ERC20Token, TokenHolder {

 

    uint256 constant public CLRS_UNIT = 10 ** 18;
    uint256 public totalSupply = 86374977 * CLRS_UNIT;

     
    uint256 constant public maxIcoSupply = 48369987 * CLRS_UNIT;            
    uint256 constant public Company = 7773748 * CLRS_UNIT;      
    uint256 constant public Bonus = 16411245 * CLRS_UNIT;   
    uint256 constant public Bounty = 1727500 * CLRS_UNIT;   
    uint256 constant public advisorsAllocation = 4318748 * CLRS_UNIT;           
    uint256 constant public CLRSinTeamAllocation = 7773748 * CLRS_UNIT;     

    
   address public constant ICOSTAKE = 0xd82896Ea0B5848dc3b75bbECc747947F64077b7c;
   address public constant COMPANY_STAKE_1 = 0x19333A742dcd220683C2231c0FAaCcb9c810C0B5;
    address public constant COMPANY_STAKE_2 = 0x19333A742dcd220683C2231c0FAaCcb9c810C0B5;
     address public constant COMPANY_STAKE_3 = 0x19333A742dcd220683C2231c0FAaCcb9c810C0B5;
      address public constant COMPANY_STAKE_4 = 0x19333A742dcd220683C2231c0FAaCcb9c810C0B5;
       address public constant COMPANY_STAKE_5 = 0x19333A742dcd220683C2231c0FAaCcb9c810C0B5;
    address public constant ADVISOR_1 = 0xf0eB71d3b31fEe5D15220A2ac418A784c962Eb53;
    address public constant ADVISOR_2 = 0xFd6b0691Cd486B4124fFD9FBe9e013463868E2B4;
    address public constant ADVISOR_3 = 0xCFb32aFA7752170043aaC32794397C8673778765;
    address public constant ADVISOR_4 = 0x08441513c0Fc653a739F34A97eF6B2B05609a4E4;
    address public constant ADVISOR_5 = 0xFd6b0691Cd486B4124fFD9FBe9e013463868E2B4;
    address public constant TEAM_1 = 0xc4896CB7486ed8821B525D858c85D4321e8e5685;
    address public constant TEAM_2 = 0x304765b9c3072E54b7397E2F55D1463BD62802C3;
    address public constant TEAM_3 = 0x46abC1d38573E8726c6C0568CC01f35fE5FF4765;
    address public constant TEAM_4 = 0x36Bf4b1DDd796eaf1f962cB0E0327C15096fae41;
    address public constant TEAM_5 = 0xc4896CB7486ed8821B525D858c85D4321e8e5685;
    address public constant BONUS_1 = 0x19333A742dcd220683C2231c0FAaCcb9c810C0B5;
    address public constant BONUS_2 = 0x19333A742dcd220683C2231c0FAaCcb9c810C0B5;
    address public constant BONUS_3 = 0x19333A742dcd220683C2231c0FAaCcb9c810C0B5;
    address public constant BONUS_4 = 0x19333A742dcd220683C2231c0FAaCcb9c810C0B5;
    address public constant BONUS_5 = 0x19333A742dcd220683C2231c0FAaCcb9c810C0B5;
    address public constant BOUNTY_1 = 0x19333A742dcd220683C2231c0FAaCcb9c810C0B5;
    address public constant BOUNTY_2 = 0x19333A742dcd220683C2231c0FAaCcb9c810C0B5;
    address public constant BOUNTY_3 = 0x19333A742dcd220683C2231c0FAaCcb9c810C0B5;
    address public constant BOUNTY_4 = 0x19333A742dcd220683C2231c0FAaCcb9c810C0B5;
    address public constant BOUNTY_5 = 0x19333A742dcd220683C2231c0FAaCcb9c810C0B5;






     
uint256 constant public COMPANY_1 = 7773744 * CLRS_UNIT;  
uint256 constant public COMPANY_2 = 1 * CLRS_UNIT;  
uint256 constant public COMPANY_3 = 1 * CLRS_UNIT;  
uint256 constant public COMPANY_4 = 1 * CLRS_UNIT;  
uint256 constant public COMPANY_5 = 1 * CLRS_UNIT;  

 
uint256 constant public ADVISOR1 = 863750 * CLRS_UNIT;  
uint256 constant public ADVISOR2 = 863750 * CLRS_UNIT;  
uint256 constant public ADVISOR3 = 431875 * CLRS_UNIT;  
uint256 constant public ADVISOR4 = 431875 * CLRS_UNIT;  
uint256 constant public ADVISOR5 = 863750 * CLRS_UNIT;  


 
uint256 constant public TEAM1 = 3876873 * CLRS_UNIT;  
uint256 constant public TEAM2 = 3876874 * CLRS_UNIT;  
uint256 constant public TEAM3 = 10000 * CLRS_UNIT;  
uint256 constant public TEAM4 = 10000 * CLRS_UNIT;  
uint256 constant public TEAM5 = 1 * CLRS_UNIT;  


 
uint256 constant public BONUS1 = 16411241 * CLRS_UNIT;  
uint256 constant public BONUS2 = 1 * CLRS_UNIT;  
uint256 constant public BONUS3 = 1 * CLRS_UNIT;  
uint256 constant public BONUS4 = 1 * CLRS_UNIT;  
uint256 constant public BONUS5 = 1 * CLRS_UNIT;  

 
uint256 constant public BOUNTY1 = 1727400 * CLRS_UNIT;  
uint256 constant public BOUNTY2 = 1 * CLRS_UNIT;  
uint256 constant public BOUNTY3 = 1 * CLRS_UNIT;  
uint256 constant public BOUNTY4 = 1 * CLRS_UNIT;  
uint256 constant public BOUNTY5 = 1 * CLRS_UNIT;  










     

uint256 public totalAllocatedToCompany = 0;      
uint256 public totalAllocatedToAdvisor = 0;         
uint256 public totalAllocatedToTEAM = 0;      
uint256 public totalAllocatedToBONUS = 0;         
uint256 public totalAllocatedToBOUNTY = 0;       

uint256 public remaintokensteam=0;
uint256 public remaintokensadvisors=0;
uint256 public remaintokensbounty=0;
uint256 public remaintokensbonus=0;
uint256 public remaintokenscompany=0;
uint256 public totremains=0;


uint256 public totalAllocated = 0;              
    uint256 public endTime;                                      

    bool internal isReleasedToPublic = false;  

    bool public isReleasedToadv = false;
    bool public isReleasedToteam = false;
 

     
    



     


    function CLRSToken()
    ERC20Token("CLRS", "CLRS", 18)
     {


        balanceOf[ICOSTAKE] = maxIcoSupply;  
        balanceOf[COMPANY_STAKE_1] = COMPANY_1;  
         balanceOf[COMPANY_STAKE_2] = COMPANY_2;  
          balanceOf[COMPANY_STAKE_3] = COMPANY_3;  
           balanceOf[COMPANY_STAKE_4] = COMPANY_4;  
            balanceOf[COMPANY_STAKE_5] = COMPANY_5;  
            totalAllocatedToCompany = safeAdd(totalAllocatedToCompany, COMPANY_1);
totalAllocatedToCompany = safeAdd(totalAllocatedToCompany, COMPANY_2);
totalAllocatedToCompany = safeAdd(totalAllocatedToCompany, COMPANY_3);
totalAllocatedToCompany = safeAdd(totalAllocatedToCompany, COMPANY_4);
totalAllocatedToCompany = safeAdd(totalAllocatedToCompany, COMPANY_5);

remaintokenscompany=safeSub(Company,totalAllocatedToCompany);

balanceOf[ICOSTAKE]=safeAdd(balanceOf[ICOSTAKE],remaintokenscompany);

        balanceOf[BONUS_1] = BONUS1;        
        balanceOf[BONUS_2] = BONUS2;        
        balanceOf[BONUS_3] = BONUS3;        
        balanceOf[BONUS_4] = BONUS4;        
        balanceOf[BONUS_5] = BONUS5;        
        totalAllocatedToBONUS = safeAdd(totalAllocatedToBONUS, BONUS1);
totalAllocatedToBONUS = safeAdd(totalAllocatedToBONUS, BONUS2);
totalAllocatedToBONUS = safeAdd(totalAllocatedToBONUS, BONUS3);
totalAllocatedToBONUS = safeAdd(totalAllocatedToBONUS, BONUS4);
totalAllocatedToBONUS = safeAdd(totalAllocatedToBONUS, BONUS5);

remaintokensbonus=safeSub(Bonus,totalAllocatedToBONUS);

balanceOf[ICOSTAKE]=safeAdd(balanceOf[ICOSTAKE],remaintokensbonus);

        balanceOf[BOUNTY_1] = BOUNTY1;        
        balanceOf[BOUNTY_2] = BOUNTY2;        
        balanceOf[BOUNTY_3] = BOUNTY3;        
        balanceOf[BOUNTY_4] = BOUNTY4;        
        balanceOf[BOUNTY_5] = BOUNTY5;        

totalAllocatedToBOUNTY = safeAdd(totalAllocatedToBOUNTY, BOUNTY1);
totalAllocatedToBOUNTY = safeAdd(totalAllocatedToBOUNTY, BOUNTY2);
totalAllocatedToBOUNTY = safeAdd(totalAllocatedToBOUNTY, BOUNTY3);
totalAllocatedToBOUNTY = safeAdd(totalAllocatedToBOUNTY, BOUNTY4);
totalAllocatedToBOUNTY = safeAdd(totalAllocatedToBOUNTY, BOUNTY5);

remaintokensbounty=safeSub(Bounty,totalAllocatedToBOUNTY);
balanceOf[ICOSTAKE]=safeAdd(balanceOf[ICOSTAKE],remaintokensbounty);


        allocateAdvisorTokens() ;
        allocateCLRSinTeamTokens();


        totremains=safeAdd(totremains,remaintokenscompany);
        totremains=safeAdd(totremains,remaintokensbounty);
        totremains=safeAdd(totremains,remaintokensbonus);
        totremains=safeAdd(totremains,remaintokensteam);
        totremains=safeAdd(totremains,remaintokensadvisors);



  burnTokens(totremains);

totalAllocated += maxIcoSupply+ totalAllocatedToCompany+ totalAllocatedToBONUS + totalAllocatedToBOUNTY;   
    }

 

     
     
    


      
         



    modifier canTransfer() {
        require( isTransferAllowedteam()==true );
        _;
    }

   modifier canTransferadv() {
        require( isTransferAllowedadv()==true );
        _;
    }


    function transfer(address _to, uint256 _value) canTransfer canTransferadv public returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) canTransfer canTransferadv public returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }





 


    function allocateCLRSinTeamTokens() public returns(bool success) {
        require(totalAllocatedToTEAM < CLRSinTeamAllocation);

        balanceOf[TEAM_1] = safeAdd(balanceOf[TEAM_1], TEAM1);        
        balanceOf[TEAM_2] = safeAdd(balanceOf[TEAM_2], TEAM2);        
        balanceOf[TEAM_3] = safeAdd(balanceOf[TEAM_3], TEAM3);         
        balanceOf[TEAM_4] = safeAdd(balanceOf[TEAM_4], TEAM4);         
        balanceOf[TEAM_5] = safeAdd(balanceOf[TEAM_5], TEAM5);        
        

       totalAllocatedToTEAM = safeAdd(totalAllocatedToTEAM, TEAM1);
totalAllocatedToTEAM = safeAdd(totalAllocatedToTEAM, TEAM2);
totalAllocatedToTEAM = safeAdd(totalAllocatedToTEAM, TEAM3);
totalAllocatedToTEAM = safeAdd(totalAllocatedToTEAM, TEAM4);
totalAllocatedToTEAM = safeAdd(totalAllocatedToTEAM, TEAM5);

totalAllocated +=  totalAllocatedToTEAM;


 remaintokensteam=safeSub(CLRSinTeamAllocation,totalAllocatedToTEAM);

balanceOf[ICOSTAKE]=safeAdd(balanceOf[ICOSTAKE],remaintokensteam);

            return true;


    }


    function allocateAdvisorTokens() public returns(bool success) {
        require(totalAllocatedToAdvisor < advisorsAllocation);

        balanceOf[ADVISOR_1] = safeAdd(balanceOf[ADVISOR_1], ADVISOR1);
        balanceOf[ADVISOR_2] = safeAdd(balanceOf[ADVISOR_2], ADVISOR2);
        balanceOf[ADVISOR_3] = safeAdd(balanceOf[ADVISOR_3], ADVISOR3);
        balanceOf[ADVISOR_4] = safeAdd(balanceOf[ADVISOR_4], ADVISOR4);
        balanceOf[ADVISOR_5] = safeAdd(balanceOf[ADVISOR_5], ADVISOR5);
        

       totalAllocatedToAdvisor = safeAdd(totalAllocatedToAdvisor, ADVISOR1);
totalAllocatedToAdvisor = safeAdd(totalAllocatedToAdvisor, ADVISOR2);
totalAllocatedToAdvisor = safeAdd(totalAllocatedToAdvisor, ADVISOR3);
totalAllocatedToAdvisor = safeAdd(totalAllocatedToAdvisor, ADVISOR4);
totalAllocatedToAdvisor = safeAdd(totalAllocatedToAdvisor, ADVISOR5);

totalAllocated +=  totalAllocatedToAdvisor;


remaintokensadvisors=safeSub(advisorsAllocation,totalAllocatedToAdvisor);

balanceOf[ICOSTAKE]=safeAdd(balanceOf[ICOSTAKE],remaintokensadvisors);

        return true;
    }



    function releaseAdvisorTokens() ownerOnly {

         isReleasedToadv = true;


    }

     function releaseCLRSinTeamTokens() ownerOnly  {

         isReleasedToteam = true;





    }



    function burnTokens(uint256 _value) ownerOnly returns(bool success) {
        uint256 amountOfTokens = _value;

        balanceOf[msg.sender]=safeSub(balanceOf[msg.sender], amountOfTokens);
        totalSupply=safeSub(totalSupply, amountOfTokens);
        Transfer(msg.sender, 0x0, amountOfTokens);
        return true;
    }



     
    function allowTransfers() ownerOnly {
        isReleasedToPublic = true;

    }

    function starttime() ownerOnly {
endTime =  now;
	}


     
    function isTransferAllowedteam() public returns(bool)
    {

        if (isReleasedToteam==true)
        return true;

        if(now < endTime + 52 weeks)

{
if(msg.sender==TEAM_1 || msg.sender==TEAM_2 || msg.sender==TEAM_3 || msg.sender==TEAM_4 || msg.sender==TEAM_5)

return false;


}


return true;
    }


 function isTransferAllowedadv() public returns(bool)
    {
        if (isReleasedToadv==true)
        return true;




        if(now < endTime + 26 weeks)

{
if(msg.sender==ADVISOR_1 || msg.sender==ADVISOR_2 || msg.sender==ADVISOR_3 || msg.sender==ADVISOR_4 || msg.sender==ADVISOR_5)

return false;


}

return true;
    }




}