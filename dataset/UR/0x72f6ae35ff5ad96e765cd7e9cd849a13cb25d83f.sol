 

pragma solidity ^0.5.11;

contract Owned {
     
    address payable owner;

     
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

     
    constructor() public {
        owner = msg.sender;
    }
}

contract MoneyPotSystem is Owned {

     
    struct Donation {
        address payable donor;
        uint amount;
    }

    struct MoneyPot {
        uint id;
        address payable author;
        address payable beneficiary;
        string name;
        string description;
        address[] donors;
        mapping(uint32 => Donation) donations;
        uint32 donationsCounter;
        bool open;
        uint feesAmount;
    }

     
    mapping(uint => MoneyPot) public moneypots;
    mapping(address => uint256[]) public addressToMoneyPot;

    uint fees;
    uint feesAmount;

    uint moneypotCounter;

    bool contractOpen;

     
    modifier onlyContractOpen() {
        require(contractOpen == true);
        _;
    }

     
    event createMoneyPotEvent (
        uint indexed _id,
        address payable indexed _author,
        string _name,
        uint _feesAmount,
        address[] _donors
    );

    event chipInEvent (
        uint indexed _id,
        address payable indexed _donor,
        uint256 _amount,
        string _name,
        uint _donation,
        uint32 indexed _donationId
    );

    event closeEvent (
        uint indexed _id,
        address payable indexed _benefeciary,
        uint256 _amount,
        string _name,
        address payable indexed _sender
    );

    event addDonorEvent(
        uint indexed _id,
        address payable indexed _donor
    );

    event feesAmountChangeEvent(
        uint _oldFeesAmount,
        uint _newFeesAmount
    );

    event withdrawFeesEvent(
        uint _feesAmount
    );

    constructor() public {
        moneypotCounter = 0;
        fees = 0;
        feesAmount = 6800000000000000;  
        contractOpen = true;
    }

    function createMoneyPot(string memory _name, string memory _description, address payable _benefeciary, address[] memory _donors) onlyContractOpen public {

        address[] memory donors = new address[](_donors.length + 1);

        address payable author = msg.sender;
        uint moneyPotId = moneypotCounter;

        uint j = 0;
        for (j; j < _donors.length; j++) {
            require(author != _donors[j]);

            donors[j] = _donors[j];
             
            addressToMoneyPot[_donors[j]].push(moneyPotId);
        }

         
        donors[j] = msg.sender;
         
        addressToMoneyPot[msg.sender].push(moneyPotId);

         
        if (msg.sender != _benefeciary) {
            addressToMoneyPot[_benefeciary].push(moneyPotId);
        }

        moneypots[moneypotCounter] = MoneyPot(moneyPotId, author, _benefeciary, _name, _description, donors, 0, true, feesAmount);

         
        emit createMoneyPotEvent(moneypotCounter, author, _name, feesAmount, _donors);

        moneypotCounter++;

    }

    function addDonor(uint _id, address payable _donor) public {

         
        require(_id >= 0 && _id <= moneypotCounter);

        MoneyPot storage myMoneyPot = moneypots[_id];

         
        require(myMoneyPot.open);

         
        require(myMoneyPot.author == msg.sender);

         
        bool donorFound = false;

        for (uint j = 0; j < myMoneyPot.donors.length; j++) {
            if (myMoneyPot.donors[j] == _donor) {
                donorFound = true;
                break;
            }
        }
        require(!donorFound);

         
        myMoneyPot.donors.push(_donor);

         
        if(myMoneyPot.beneficiary != _donor) {
            addressToMoneyPot[_donor].push(_id);
        }

        emit addDonorEvent(_id, _donor);
    }
     
    function getNumberOfMoneyPots() public view returns (uint256) {
        return moneypotCounter;
    }

    function getNumberOfMyMoneyPots() public view returns (uint256) {
        return addressToMoneyPot[msg.sender].length;
    }

    function getMyMoneyPotsIds(address who) public view returns (uint256[] memory) {
        return addressToMoneyPot[who];
    }

    function getDonors(uint256 moneyPotId) public view returns (address[] memory) {
        return moneypots[moneyPotId].donors;
    }

    function getDonation(uint moneyPotId, uint32 donationId) public view returns (address donor, uint amount) {

        Donation storage donation = moneypots[moneyPotId].donations[donationId];

        return (donation.donor, donation.amount);
    }

    function chipIn(uint _id) payable public {
        require(moneypotCounter > 0);

         
        require(_id >= 0 && _id <= moneypotCounter);

         
        MoneyPot storage myMoneyPot = moneypots[_id];

         
        require(myMoneyPot.open);

         
        bool donorFound = false;

        for (uint j = 0; j < myMoneyPot.donors.length; j++) {
            if (myMoneyPot.donors[j] == msg.sender) {
                donorFound = true;
                break;
            }
        }

        require(donorFound);

        fees = fees + myMoneyPot.feesAmount;

        uint donation = msg.value - myMoneyPot.feesAmount;

         
        myMoneyPot.donations[myMoneyPot.donationsCounter] = Donation(msg.sender, donation);

         
        emit chipInEvent(_id, msg.sender, msg.value, myMoneyPot.name, donation, myMoneyPot.donationsCounter);

        myMoneyPot.donationsCounter += 1;

    }

    function withdrawFees() onlyOwner public {
        owner.transfer(fees);
        emit withdrawFeesEvent(fees);
        fees = 0;
    }

    function getFeesAmount() public view returns (uint) {
        return feesAmount;
    }

    function setFeesAmount(uint _amount) onlyOwner public {
        require(feesAmount != _amount);

        emit feesAmountChangeEvent(feesAmount, _amount);
        feesAmount = _amount;
    }

    function getFees() onlyOwner public view returns (uint) {
        return fees;
    }

    function getMoneyPotAmount(uint _id) public view returns (uint256) {
        require(moneypotCounter > 0);

         
        require(_id >= 0 && _id <= moneypotCounter);

         
        MoneyPot storage myMoneyPot = moneypots[_id];

        uint256 amount = 0;

        for (uint32 j = 0; j < myMoneyPot.donationsCounter; j++) {
            amount += myMoneyPot.donations[j].amount;
        }

        return amount;
    }

    function close(uint _id) public {
        require(moneypotCounter > 0);

        require(_id >= 0 && _id <= moneypotCounter);

        MoneyPot storage myMoneyPot = moneypots[_id];

         
        require(msg.sender == myMoneyPot.author || msg.sender == myMoneyPot.beneficiary || msg.sender == owner);

         
        require(myMoneyPot.open);

        uint amount = getMoneyPotAmount(myMoneyPot.id);

        myMoneyPot.open = false;

        myMoneyPot.beneficiary.transfer(amount);

        emit closeEvent(_id, myMoneyPot.beneficiary, amount, myMoneyPot.name, msg.sender);
    }

    function closeAllMoneypot() onlyOwner public {

        for (uint i = 0; i < moneypotCounter; i++) {

            MoneyPot storage moneyPot = moneypots[i];
            if (moneyPot.open) {
                close(moneyPot.id);
            }
        }
    }

    function closeContract() onlyOwner public {
        require(contractOpen);
        contractOpen = false;
    }

    function openContract() onlyOwner public {
        require(!contractOpen);
        contractOpen = true;
    }

    function isOpen() public view returns (bool) {
        return contractOpen;
    }

     
    function kill() onlyOwner public {
        withdrawFees();
        closeAllMoneypot();
        selfdestruct(owner);
    }
}