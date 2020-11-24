 

pragma solidity ^0.4.20;

 

contract Lottery{

      

    
    modifier onlyOwner()
    {
        require(msg.sender == owner);
        _;
    }

    
    modifier notPooh(address aContract)
    {
        require(aContract != address(revContract));
        _;
    }

    modifier isOpenToPublic()
    {
        require(openToPublic);
        _;
    }


     


    event Deposit(
        uint256 amount,
        address depositer
    );

    event WinnerPaid(
        uint256 amount,
        address winner
    );


     

    REV revContract;   
    address owner;
    bool openToPublic = false;  
    uint256 ticketNumber = 0;  
    uint256 winningNumber;  


     

    constructor() public
    {
        revContract = REV(0x05215FCE25902366480696F38C3093e31DBCE69A);
        openToPublic = false;
        owner = 0xc42559F88481e1Df90f64e5E9f7d7C6A34da5691;
    }


   
    function() payable public { }


    function deposit()
       isOpenToPublic()
     payable public
     {
         
        require(msg.value >= 10000000000000000);
        address customerAddress = msg.sender;

         
        revContract.buy.value(msg.value)(customerAddress);
        emit Deposit(msg.value, msg.sender);

         
        if(msg.value > 10000000000000000)
        {
            uint extraTickets = SafeMath.div(msg.value, 10000000000000000);  
            
             
            ticketNumber += extraTickets;
        }

          
        if(ticketNumber >= winningNumber)
        {
             
            revContract.exit();

             
            payDev(owner);

             
            payWinner(customerAddress);

             
            resetLottery();
        }
        else
        {
            ticketNumber++;
        }
    }

     
    function myTokens() public view returns(uint256)
    {
        return revContract.myTokens();
    }


      
    function myDividends() public view returns(uint256)
    {
        return revContract.myDividends(true);
    }

    
    function ethBalance() public view returns (uint256)
    {
        return address(this).balance;
    }


      

     
    function openToThePublic()
       onlyOwner()
        public
    {
        openToPublic = true;
        resetLottery();
    }

     
    function emergencyStop()
        onlyOwner()
        public
    {
        
        revContract.exit();
        uint balance = address(this).balance;
        owner.transfer(balance);

         
        openToPublic = false;
    }


      
    function returnAnyERC20Token(address tokenAddress, address tokenOwner, uint tokens)

    public
    onlyOwner()
    notPooh(tokenAddress)
    returns (bool success)
    {
        return ERC20Interface(tokenAddress).transfer(tokenOwner, tokens);
    }


      


      
    function payWinner(address winner) internal
    {
        uint balance = address(this).balance;
        winner.transfer(balance);

        emit WinnerPaid(balance, winner);
    }

     
    function payDev(address dev) internal
    {
        uint balance = SafeMath.div(address(this).balance, 10);
        dev.transfer(balance);
    }

    function resetLottery() internal
    {
        ticketNumber = 1;
        winningNumber = uint256(keccak256(block.timestamp, block.difficulty))%300;
    }

    function resetLotteryManually() public
    onlyOwner()
    {
        ticketNumber = 1;
        winningNumber = uint256(keccak256(block.timestamp, block.difficulty))%300;
    }


}


 
contract ERC20Interface
{
    function transfer(address to, uint256 tokens) public returns (bool success);
}

 
contract REV
{
    function buy(address) public payable returns(uint256);
    function exit() public;
    function myTokens() public view returns(uint256);
    function myDividends(bool) public view returns(uint256);
}

library SafeMath {

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
        return a / b;
    }
}