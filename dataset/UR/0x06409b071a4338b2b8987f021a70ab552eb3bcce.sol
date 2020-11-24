 

pragma solidity ^0.4.25;

 


interface IERC20Token {
    function balanceOf(address owner) external returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function decimals() external returns (uint256);
}

contract SpecialTransferContract {
    IERC20Token public tokenContract;   
    address public owner;                
    uint256 public tokensDistributed;           
    uint256 public acceptableEthAmountInWei;  
    uint256 public tokensPerContributor;     
    uint256 public contributionsMade;  
    bytes32 contractOwner;  

    event Contribution(address buyer, uint256 amount);  

    constructor(bytes32 _contractOwner, IERC20Token _tokenContract) public {
        owner = msg.sender;
        contractOwner = _contractOwner;
        tokenContract = _tokenContract; 
    }    

    
    function ConfigurableParameters(uint256 _tokensPerContributor, uint256 _acceptableEthAmountInWei) public {
        require(msg.sender == owner);  
        tokensPerContributor = _tokensPerContributor;
        acceptableEthAmountInWei = _acceptableEthAmountInWei;
    }
    
    
    function () payable public {
     
    require(msg.sender != owner);   

    
    acceptContribution();
    emit Contribution(msg.sender, tokensPerContributor);  
    owner.transfer(msg.value);  
    }
    
    
    function acceptContribution() public payable {
         
        require(tokenContract.balanceOf(this) >= tokensPerContributor);
        
         
        require(msg.value == acceptableEthAmountInWei);

         
        tokensDistributed += tokensPerContributor;
        contributionsMade += 1;

        require(tokenContract.transfer(msg.sender, tokensPerContributor));
    }

    function endSale() public {
        require(msg.sender == owner);

         
        require(tokenContract.transfer(owner, tokenContract.balanceOf(this)));

         
        msg.sender.transfer(address(this).balance);
    }
}