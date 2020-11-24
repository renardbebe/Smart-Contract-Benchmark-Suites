 

pragma solidity ^0.4.24;

 

contract Kman{

      

    
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
    
    
     


   event WinnerPaid
   (
        uint256 amount,
        address winner
    );
    
    event StartGame
    (
        address player
    );

     

    BIT BITcontract;   
    address owner;
    bool openToPublic = false; 
    mapping(address => uint256) paidPlayers;


     

    constructor() public
    {
        BITcontract = BIT(0x645f0c9695F2B970E623aE29538FdB1A67bd6b6E);  
        openToPublic = false;
        owner = msg.sender;
    }

     function start()
       isOpenToPublic()
       onlyRealPeople()
      public
      returns(bool startGame)
     {
        startGame = false;
        uint256 tokensTransferred = getTokensPaidToGame(msg.sender);

         
        if( tokensTransferred > paidPlayers[msg.sender])  
        {
             
            paidPlayers[msg.sender] = tokensTransferred;
             
            BITcontract.transfer(owner, 50000000000000000);  
             
            emit StartGame(msg.sender);

            return true;
        }
        else
        {
            revert();
        }
    }

    function BITBalanceOf(address someAddress) public view returns(uint256)
    {
        return BITcontract.balanceOf(someAddress);
    }
    
    function getTokensPaidToGame(address customerAddress) public view returns (uint256)
    {
       return BITcontract.gamePlayers(address(this), customerAddress);
    }

    function firstPlacePot() public view returns(uint256)
    {
       uint256 balance = BITBalanceOf(this);
       return balance / 4;
    }
    
    function secondPlacePot() public view returns(uint256)
    {
       uint256 balance = BITBalanceOf(this);
       return (balance * 15)/ 100;
    }
    
    function thirdPlacePot() public view returns(uint256)
    {
       uint256 balance = BITBalanceOf(this);
       return balance / 10;
    }

   

      

    
    function openToThePublic()
       onlyOwner()
        public
    {
        openToPublic = true;
    }

     
    function PayWinners(uint place, address winner) 
    public 
    isOpenToPublic()
    onlyRealPeople() 
    onlyOwner()
    {
        uint256 awardAmount = 0;
       if(place == 1)
       {
           awardAmount = firstPlacePot();
           BITcontract.transfer(winner, awardAmount);
           
       }
       else if(place == 2 )
       {
            awardAmount = secondPlacePot();
            BITcontract.transfer(winner, awardAmount);
       }
       else if(place ==3)
       {
            awardAmount = thirdPlacePot();
            BITcontract.transfer(winner, awardAmount);
       }
      
      emit WinnerPaid(awardAmount, winner);
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