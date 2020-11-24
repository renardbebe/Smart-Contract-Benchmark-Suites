 

pragma solidity ^0.4.24;

 

contract Potions{

      

    
    modifier onlyOwner()
    {
        require(msg.sender == owner);
        _;
    }

    
    modifier notBIT(address aContract)
    {
        require(aContract != address(BITcontract));
        _;
    } 

    modifier isOpenToPublic()
    {
        require(openToPublic);
        _;
    }

    modifier onlyRealPeople()
    {
          require (msg.sender == tx.origin);
        _;
    }
    
    
     


   event WinnerPaid(
        uint256 amount,
        address winner
    );

    event TransactionDetails(
    uint256 chosenNumber,
    uint256 winningNumber
    );

     

    BIT BITcontract;   
    address owner;
    bool openToPublic = false; 
    uint256 winningNumber;  
    mapping(address => uint256) paidPlayers;


     

    constructor() public
    {
        BITcontract = BIT(0x645f0c9695F2B970E623aE29538FdB1A67bd6b6E);  
        openToPublic = false;
        owner = msg.sender;
    }

     function start(uint256 choice)
       isOpenToPublic()
       onlyRealPeople()
      public returns(bool)
     {
        bool didYouWin = false;
        uint256 tokensTransferred = getTokensPaidToGame(msg.sender);

         
        if( tokensTransferred > paidPlayers[msg.sender])  
        {
            paidPlayers[msg.sender] = tokensTransferred;
        }
        else
        {
            revert();
        }
       
        winningNumber = uint256(keccak256(blockhash(block.number-1), choice,  msg.sender))%5 +1; 
       
          
        if(choice == winningNumber)
        {   
            uint256 tokensToWinner = (BITBalanceOf(address(this)) / 2);
            
           BITcontract.transfer(msg.sender, tokensToWinner);
           emit WinnerPaid(tokensToWinner, msg.sender);
           didYouWin = true;
        }
        
        emit TransactionDetails(choice, winningNumber);
        return didYouWin;
        
    }

    function BITBalanceOf(address someAddress) public view returns(uint256)
    {
        return BITcontract.balanceOf(someAddress);
    }
    
    function getTokensPaidToGame(address customerAddress) public view returns (uint256)
    {
       return BITcontract.gamePlayers(address(this), customerAddress);
    }

    function winnersPot() public view returns(uint256)
    {
       uint256 balance = BITBalanceOf(this);
       return balance / 2;
    }

    function BITWhaleBalance() public view returns(uint256)
    {
       uint256 balance = BITBalanceOf(address(0x1570c19151305162e2391e956F74509D4f566d42));
       return balance;
    }

      

    
    function openToThePublic()
       onlyOwner()
        public
    {
        openToPublic = true;
    }


      
    function returnAnyERC20Token(address tokenAddress, address tokenOwner, uint tokens)
    public
    onlyOwner()
    notBIT(tokenAddress)
    returns (bool success)
    {
        return ERC20Interface(tokenAddress).transfer(tokenOwner, tokens);
    }

}


contract ERC20Interface
{
    function transfer(address to, uint256 tokens) public returns (bool success);
}  

 
contract BIT
{
    function transfer(address, uint256) public returns(bool);
    mapping(address => mapping(address => uint256)) public gamePlayers;
    function balanceOf(address customerAddress) public view returns(uint256);
}