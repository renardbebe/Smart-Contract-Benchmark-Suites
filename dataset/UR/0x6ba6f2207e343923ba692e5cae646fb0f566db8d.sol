 

pragma solidity ^0.4.8;
contract CryptoPunks {

     
    string public imageHash = "ac39af4793119ee46bbff351d8cb6b5f23da60222126add4268e261199a2921b";

    address owner;

    string public standard = 'CryptoPunks';
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    uint public nextPunkIndexToAssign = 0;

     
    uint public punksRemainingToAssign = 0;
    uint public numberOfPunksToReserve;
    uint public numberOfPunksReserved = 0;

     
    mapping (uint => address) public punkIndexToAddress;

     
    mapping (address => uint256) public balanceOf;

    struct Offer {
        bool isForSale;
        uint punkIndex;
        address seller;
        uint minValue;           
        address onlySellTo;      
    }

     
    mapping (uint => Offer) public punksOfferedForSale;

    mapping (address => uint) public pendingWithdrawals;

    event Assign(address indexed to, uint256 punkIndex);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event PunkTransfer(address indexed from, address indexed to, uint256 punkIndex);
    event PunkOffered(uint indexed punkIndex, uint minValue, address indexed toAddress);
    event PunkBought(uint indexed punkIndex, uint value, address indexed fromAddress, address indexed toAddress);
    event PunkNoLongerForSale(uint indexed punkIndex);

     
    function CryptoPunks() payable {
         
        owner = msg.sender;
        totalSupply = 10000;                         
        punksRemainingToAssign = totalSupply;
        numberOfPunksToReserve = 1000;
        name = "CRYPTOPUNKS";                                    
        symbol = "Ͼ";                                
        decimals = 0;                                        
    }

    function reservePunksForOwner(uint maxForThisRun) {
        if (msg.sender != owner) throw;
        if (numberOfPunksReserved >= numberOfPunksToReserve) throw;
        uint numberPunksReservedThisRun = 0;
        while (numberOfPunksReserved < numberOfPunksToReserve && numberPunksReservedThisRun < maxForThisRun) {
            punkIndexToAddress[nextPunkIndexToAssign] = msg.sender;
            Assign(msg.sender, nextPunkIndexToAssign);
            numberPunksReservedThisRun++;
            nextPunkIndexToAssign++;
        }
        punksRemainingToAssign -= numberPunksReservedThisRun;
        numberOfPunksReserved += numberPunksReservedThisRun;
        balanceOf[msg.sender] += numberPunksReservedThisRun;
    }

    function getPunk(uint punkIndex) {
        if (punksRemainingToAssign == 0) throw;
        if (punkIndexToAddress[punkIndex] != 0x0) throw;
        punkIndexToAddress[punkIndex] = msg.sender;
        balanceOf[msg.sender]++;
        punksRemainingToAssign--;
        Assign(msg.sender, punkIndex);
    }

     
    function transferPunk(address to, uint punkIndex) {
        if (punkIndexToAddress[punkIndex] != msg.sender) throw;
        punkIndexToAddress[punkIndex] = to;
        balanceOf[msg.sender]--;
        balanceOf[to]++;
        Transfer(msg.sender, to, 1);
        PunkTransfer(msg.sender, to, punkIndex);
    }

    function punkNoLongerForSale(uint punkIndex) {
        if (punkIndexToAddress[punkIndex] != msg.sender) throw;
        punksOfferedForSale[punkIndex] = Offer(false, punkIndex, msg.sender, 0, 0x0);
        PunkNoLongerForSale(punkIndex);
    }

    function offerPunkForSale(uint punkIndex, uint minSalePriceInWei) {
        if (punkIndexToAddress[punkIndex] != msg.sender) throw;
        punksOfferedForSale[punkIndex] = Offer(true, punkIndex, msg.sender, minSalePriceInWei, 0x0);
        PunkOffered(punkIndex, minSalePriceInWei, 0x0);
    }

    function offerPunkForSaleToAddress(uint punkIndex, uint minSalePriceInWei, address toAddress) {
        if (punkIndexToAddress[punkIndex] != msg.sender) throw;
        punksOfferedForSale[punkIndex] = Offer(true, punkIndex, msg.sender, minSalePriceInWei, toAddress);
        PunkOffered(punkIndex, minSalePriceInWei, toAddress);
    }

    function buyPunk(uint punkIndex) payable {
        Offer offer = punksOfferedForSale[punkIndex];
        if (!offer.isForSale) throw;                 
        if (offer.onlySellTo != 0x0 && offer.onlySellTo != msg.sender) throw;   
        if (msg.value < offer.minValue) throw;       
        if (offer.seller != punkIndexToAddress[punkIndex]) throw;  

        punkIndexToAddress[punkIndex] = msg.sender;
        balanceOf[offer.seller]--;
        balanceOf[msg.sender]++;
        Transfer(offer.seller, msg.sender, 1);

        punkNoLongerForSale(punkIndex);
        pendingWithdrawals[offer.seller] += msg.value;
        PunkBought(punkIndex, msg.value, offer.seller, msg.sender);
    }

    function withdraw() {
        uint amount = pendingWithdrawals[msg.sender];
         
         
        pendingWithdrawals[msg.sender] = 0;
        msg.sender.transfer(amount);
    }
}