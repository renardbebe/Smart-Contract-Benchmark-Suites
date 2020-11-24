 

pragma solidity ^0.5.8;

 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
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

 
contract Ownable {
    address internal owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) onlyOwner public returns (bool) {
        require(newOwner != address(0x0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;

        return true;
    }
}


 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused, "Contract is Paused");
    _;
  }

   
  modifier whenPaused() {
    require(paused, "Contract is unpaused");
    _;
  }

   
  function pause() public onlyOwner whenNotPaused {
    paused = true;
    emit Pause();
  }

   
  function unpause() public onlyOwner whenPaused {
    paused = false;
    emit Unpause();
  }
}


contract ERC20 {
    uint256 public totalSupply;

    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


contract NanakShahiDistribution is Ownable, Pausable {
    
    ERC20 NannakTokenAddress;
    
    address advisorAddress;
    address founderAddress;
    address teamAddress;
    address reserveAddress;
    
    uint256 public totalSupply = SafeMath.mul(1000000000, 1 ether);
    uint256 internal publicSupply = SafeMath.mul(SafeMath.div(totalSupply,100),50);
    uint256 internal reserveSupply = SafeMath.mul(SafeMath.div(totalSupply,100),14);
    uint256 internal teamSupply = SafeMath.mul(SafeMath.div(totalSupply,100),13);
    uint256 internal advisorSupply = SafeMath.mul(SafeMath.div(totalSupply,100),3);
    uint256 internal bountySupply = SafeMath.mul(SafeMath.div(totalSupply,100),5);
    uint256 internal founderSupply = SafeMath.mul(SafeMath.div(totalSupply,100),15);
    
    bool internal grantAdvisorSupply;
    bool internal grantFounderSupply;
    bool internal grantTeamSupply;

    constructor () public {
        NannakTokenAddress = ERC20(0xEE01970f0620Aa69A1978394ABe9a3521061BddA);
        
        advisorAddress = address(0x819acdf6731B51Dd7E68D5DfB6f602BBD8E62871);
        founderAddress = address(0x996f2959cE684B2cA221b9f0Da41899662220953);
        teamAddress = address(0x3c61fD8BDFf22C3Aa309f52793288CfB8A271325);
        reserveAddress = address(0x3501C88dCEAC658014d6C4406E0D39e11a7e0340);
        
        grantAdvisorSupply = false;
        grantFounderSupply = false;
        grantTeamSupply = false;

    }    

    event TransferBountyTokens(address [] beneficiary, uint256[] tokens);
    event TransferReservedTokens(address reserveAddress, uint256 reserveSupply);   
    event TransferAdvisorTokens(address advisorAddress, uint256 advisorSupply);
    event TransferFounderTokens(address founderAddress, uint256 founderSupply);
    event TransferTeamTokens(address teamAddress, uint256 teamSupply);
    event TransferPublicTokens(address beneficiary, uint256 tokens);
    
    
     

    function bountyFunds(address[] memory beneficiary, uint256[] memory tokens) onlyOwner whenNotPaused public {
        for (uint256 i = 0; i < beneficiary.length; i++) {
            tokens[i] = SafeMath.mul(tokens[i],1 ether); 
            
            require(bountySupply >= tokens[i], "Remaining bounty supply is less");
            
            bountySupply = SafeMath.sub(bountySupply,tokens[i]);
            NannakTokenAddress.transfer(beneficiary[i], tokens[i]);
        }
    
    emit TransferBountyTokens(beneficiary, tokens);
    }

     
    
    function reserveFunds() onlyOwner whenNotPaused public { 
        require(reserveSupply > 0, "Reserve supply is 0");
        NannakTokenAddress.transfer(reserveAddress, reserveSupply);
        reserveSupply = 0;
        
        emit TransferReservedTokens(reserveAddress, reserveSupply);    
    }
    
     
    
    function grantAdvisorToken() onlyOwner whenNotPaused public {
    
        require(!grantAdvisorSupply, "Advisor supply already taken");
        require(advisorSupply > 0, "Advisor supply is 0");
            
        NannakTokenAddress.transfer(advisorAddress, advisorSupply);
                
        emit TransferAdvisorTokens(advisorAddress, advisorSupply);
        
        advisorSupply = 0;
    }

     
    
    function grantFounderToken() onlyOwner whenNotPaused public {
    
        require(!grantFounderSupply);
        require(founderSupply > 0, "Founder Supply is 0");
        
        NannakTokenAddress.transfer(founderAddress, founderSupply);
        
        emit TransferFounderTokens(founderAddress, founderSupply);
           
        founderSupply = 0;
    }

    
    
    function grantTeamToken() onlyOwner whenNotPaused public {
        
        require(!grantTeamSupply);
        require(teamSupply > 0, "Team Suuply is 0");
        
        NannakTokenAddress.transfer(teamAddress, teamSupply);
        
        emit TransferTeamTokens(teamAddress, teamSupply);
        teamSupply = 0;
    }
    
     
      function transferToken(address beneficiary, uint256 tokens) onlyOwner whenNotPaused public {
    
        require(publicSupply > 0, "Public Supply is 0");
        tokens = SafeMath.mul(tokens, 1 ether);
     
        require(publicSupply >= tokens, "Public Supply is less");
        publicSupply = SafeMath.sub(publicSupply, tokens);
        NannakTokenAddress.transfer(beneficiary, tokens);
    
        emit TransferPublicTokens(beneficiary, tokens);
      }
}