 

pragma solidity ^0.4.24;

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
 
 
 
 
 
 
 

pragma solidity ^0.4.24;


contract MyanmarDonations{

     
    address public SENC_CONTRACT_ADDRESS = 0xA13f0743951B4f6E3e3AA039f682E17279f52bc3;
     
    address public donationWallet;
     
    address public foundationWallet;
     
    uint256 public startDate;
     
    uint256 public endDate;
     
    uint256 public sencEthRate;

     
    uint256 public ETHER_HARD_CAP;
     
    uint256 public INFOCORP_DONATION;
     
    uint256 public TOTAL_ETHER_HARD_CAP;
     
    uint256 public totalSencCollected;
     
    bool public finalized = false;

    uint256 public sencHardCap;

    modifier onlyDonationAddress() {
        require(msg.sender == donationWallet);
        _;
    }

    constructor(                           
                address _donationWallet,  
                address _foundationWallet,  
                uint256 _startDate,  
                uint256 _endDate,  
                uint256 _sencEthRate,  
                uint256 _etherHardCap,
                uint256 _infocorpDonation
                ) public {
        donationWallet = _donationWallet;
        foundationWallet = _foundationWallet;
        startDate = _startDate;
        endDate = _endDate;
        sencEthRate = _sencEthRate;
        ETHER_HARD_CAP = _etherHardCap;
        sencHardCap = ETHER_HARD_CAP * 10 ** 18 / sencEthRate;
        INFOCORP_DONATION = _infocorpDonation;

        TOTAL_ETHER_HARD_CAP = ETHER_HARD_CAP + INFOCORP_DONATION;
    }

     
    function() public payable {
        require(msg.value == TOTAL_ETHER_HARD_CAP);
        require(
            address(this).balance <= TOTAL_ETHER_HARD_CAP,
            "Contract balance hardcap reachead"
        );
    }

     
    function finalize() public onlyDonationAddress returns (bool) {
        require(getSencBalance() >= sencHardCap || now >= endDate, "SENC hard cap rached OR End date reached");
        require(!finalized, "Donation not already finalized");
         
        totalSencCollected = getSencBalance();
        if (totalSencCollected >= sencHardCap) {
             
            donationWallet.transfer(address(this).balance);
        } else {
            uint256 totalDonatedEthers = convertToEther(totalSencCollected) + INFOCORP_DONATION;
             
            donationWallet.transfer(totalDonatedEthers);
             
            claimTokens(address(0), foundationWallet);
        }
         
        claimTokens(SENC_CONTRACT_ADDRESS, foundationWallet);
        finalized = true;
        return finalized;
    }

     
    function claimTokens(address _token, address _to) public onlyDonationAddress {
        require(_to != address(0), "Wallet format error");
        if (_token == address(0)) {
            _to.transfer(address(this).balance);
            return;
        }

        ERC20Basic token = ERC20Basic(_token);
        uint256 balance = token.balanceOf(this);
        require(token.transfer(_to, balance), "Token transfer unsuccessful");
    }

     
    function sencToken() public view returns (ERC20Basic) {
        return ERC20Basic(SENC_CONTRACT_ADDRESS);
    }

     
    function getSencBalance() public view returns (uint256) {
        return sencToken().balanceOf(address(this));
    }

     
    function getTotalDonations() public view returns (uint256) {
        return convertToEther(finalized ? totalSencCollected : getSencBalance());
    }
    
     
    function setEndDate(uint256 _endDate) external onlyDonationAddress returns (bool){
        endDate = _endDate;
        return true;
    }

     
    function convertToEther(uint256 _value) public view returns (uint256) {
        return _value * sencEthRate / 10 ** 18;
    }

}