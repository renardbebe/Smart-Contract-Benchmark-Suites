 

pragma solidity ^0.4.25;

 

contract Bankroll {
    
    uint256 public gooPurchaseAllocation;  
    uint256 public tokenPurchaseAllocation;  
    address public owner;
    
    GooBurnAlgo public gooBurner = GooBurnAlgo(0x0);
    Clans clans = Clans(0x0);
    address constant gooToken = address(0xdf0960778c6e6597f197ed9a25f12f5d971da86c);
    event TokenPurchase(address tokenAddress, uint256 tokensBought, uint256 reimbursementWei);
    
    constructor() public {
        owner = msg.sender;
    }
    
    function() payable external {
         
    }
    
    function setClans(address clansContract) external {
        require(msg.sender == owner);
        clans = Clans(clansContract);
    }
    
    function depositEth(uint256 gooAllocation, uint256 tokenAllocation) payable external {
        require(gooAllocation <= 100);
        require(tokenAllocation <= 100);
        require(gooAllocation + tokenAllocation <= 100);
        
        gooPurchaseAllocation += (msg.value * gooAllocation) / 100;
        tokenPurchaseAllocation += (msg.value * tokenAllocation) / 100;
    }
    
    function updateGooBurnAlgo(address config) external {
        require(msg.sender == owner);
        gooBurner = GooBurnAlgo(config);
    }
    
     
    function refundTokenPurchase(uint256 clanId, uint256 tokensAmount, uint256 reimbursement) external {
        require(msg.sender == owner);
        require(tokensAmount > 0);
        require(clans.exists(clanId));
        
         
        address tokenAddress = clans.clanToken(clanId);
        require(ERC20(tokenAddress).transferFrom(owner, address(clans), tokensAmount));
        
         
        require(reimbursement >= tokenPurchaseAllocation);
        tokenPurchaseAllocation -= reimbursement;
        owner.transfer(reimbursement);
        
         
        emit TokenPurchase(tokenAddress, tokensAmount, reimbursement);
    }
    
    function increaseGooPurchaseAllocation(uint256 newAllocation) external {
        require(msg.sender == owner);
        require(newAllocation < (address(this).balance - tokenPurchaseAllocation));
        gooPurchaseAllocation = newAllocation;
    }
    
    function increaseTokenPurchaseAllocation(uint256 newAllocation) external {
        require(msg.sender == owner);
        require(newAllocation < (address(this).balance - gooPurchaseAllocation));
        tokenPurchaseAllocation = newAllocation;
    }
    
    function receiveApproval(address player, uint256 amount, address, bytes) external {
        require(msg.sender == gooToken);
        
         
        uint256 payment = gooBurner.priceOf(amount);
        require(payment <= gooPurchaseAllocation);
        
         
        ERC20(msg.sender).transferFrom(player, address(0), amount);
        
         
        gooPurchaseAllocation -= payment;
        player.transfer(payment);
    }
    
}

contract GooBurnAlgo {
    
    Bankroll constant bankroll = Bankroll(0x66a9f1e53173de33bec727ef76afa84956ae1b25);
    GooToken constant goo = GooToken(0xdf0960778c6e6597f197ed9a25f12f5d971da86c);

    address public owner;  

    constructor() public {
        owner = msg.sender;
    }
    
     
    function priceOf(uint256 amount) external view returns(uint256 payment) {
        payment = (bankroll.gooPurchaseAllocation() * amount) / (goo.totalSupply() * 2);
    }
    
    function price() external view returns(uint256 gooPrice) {
        gooPrice = bankroll.gooPurchaseAllocation() / (goo.totalSupply() * 2);
    }
    
}

contract Clans {
    function exists(uint256 clanId) public view returns (bool);
    mapping(uint256 => address) public clanToken;  
}

contract GooToken {
    function totalSupply() external view returns(uint256);
}

contract ERC20 {
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
}