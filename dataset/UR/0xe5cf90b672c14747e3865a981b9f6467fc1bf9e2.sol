 

pragma solidity 0.5.11;

 

 

 
library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

     
     
     
     
     
     
     
     

     
     

     
     

     
     
     
     
     
     

     
     

     
     
     
     
     
}

 
contract XEuro {

     
    function balanceOf(address _account) external view returns (uint);

     
    function transfer(address _recipient, uint _amount) external returns (bool);

}

 
contract CryptonomicaVerification {

     
    function revokedOn(address _address) external view returns (uint unixTime);

     
    function keyCertificateValidUntil(address _address) external view returns (uint unixTime);
}

 
contract ERC223ReceivingContract {
     
    function tokenFallback(address _from, uint _value, bytes calldata _data) external;
}

 
contract CryptoShares {

    using SafeMath for uint256;

     
    uint public contractNumberInTheLedger;

     
    string public description;

     

    CryptonomicaVerification public cryptonomicaVerification;

     
    function addressIsVerifiedByCryptonomica(address _address) public view returns (bool){
        return cryptonomicaVerification.keyCertificateValidUntil(_address) > now && cryptonomicaVerification.revokedOn(_address) == 0;
    }

     

     
    XEuro public xEuro;

     

    string public name;

    string public symbol;

    uint8 public constant decimals = 0;

    uint public totalSupply;

    mapping(address => uint) public balanceOf;

    mapping(address => mapping(address => uint)) public allowance;

     
    address public creator;

     
    constructor() public {
         
        creator = msg.sender;
    }

     

     
    event Transfer(address indexed from, address indexed to, uint value);

    event Approval(address indexed _owner, address indexed spender, uint value);

     

     
    event DataSentToAnotherContract(
        address indexed from,
        address indexed toContract,
        bytes indexed extraData
    );

     

     

     
    string public disputeResolutionAgreement;

     
    uint256 public disputeResolutionAgreementSignaturesCounter;

     
    struct Signature {
        uint signatureNumber;
        uint shareholderId;
        address signatoryRepresentedBy;
        string signatoryName;
        string signatoryRegistrationNumber;
        string signatoryAddress;
        uint signedOnUnixTime;
    }

     
    mapping(uint256 => Signature) public disputeResolutionAgreementSignaturesByNumber;

     
    mapping(address => uint) public addressSignaturesCounter;

     
    mapping(address => mapping(uint => Signature)) public signaturesByAddress;

     
    event disputeResolutionAgreementSigned(
        uint256 indexed signatureNumber,
        address indexed signatoryRepresentedBy,
        string signatoryName,
        uint indexed signatoryShareholderId,
        string signatoryRegistrationNumber,
        string signatoryAddress,
        uint signedOnUnixTime
    );

     
    function signDisputeResolutionAgreement(
        uint _shareholderId,
        string memory _signatoryName,
        string memory _signatoryRegistrationNumber,
        string memory _signatoryAddress
    ) private {

        require(
            addressIsVerifiedByCryptonomica(msg.sender),
            "Signer has to be verified on Cryptonomica.net"
        );

        disputeResolutionAgreementSignaturesCounter++;
        addressSignaturesCounter[msg.sender] = addressSignaturesCounter[msg.sender] + 1;

        disputeResolutionAgreementSignaturesByNumber[disputeResolutionAgreementSignaturesCounter].signatureNumber = disputeResolutionAgreementSignaturesCounter;
        disputeResolutionAgreementSignaturesByNumber[disputeResolutionAgreementSignaturesCounter].shareholderId = _shareholderId;
        disputeResolutionAgreementSignaturesByNumber[disputeResolutionAgreementSignaturesCounter].signatoryRepresentedBy = msg.sender;
        disputeResolutionAgreementSignaturesByNumber[disputeResolutionAgreementSignaturesCounter].signatoryName = _signatoryName;
        disputeResolutionAgreementSignaturesByNumber[disputeResolutionAgreementSignaturesCounter].signatoryRegistrationNumber = _signatoryRegistrationNumber;
        disputeResolutionAgreementSignaturesByNumber[disputeResolutionAgreementSignaturesCounter].signatoryAddress = _signatoryAddress;
        disputeResolutionAgreementSignaturesByNumber[disputeResolutionAgreementSignaturesCounter].signedOnUnixTime = now;

        signaturesByAddress[msg.sender][addressSignaturesCounter[msg.sender]] = disputeResolutionAgreementSignaturesByNumber[disputeResolutionAgreementSignaturesCounter];

        emit disputeResolutionAgreementSigned(
            disputeResolutionAgreementSignaturesCounter,
            disputeResolutionAgreementSignaturesByNumber[disputeResolutionAgreementSignaturesCounter].signatoryRepresentedBy,
            disputeResolutionAgreementSignaturesByNumber[disputeResolutionAgreementSignaturesCounter].signatoryName,
            disputeResolutionAgreementSignaturesByNumber[disputeResolutionAgreementSignaturesCounter].shareholderId,
            disputeResolutionAgreementSignaturesByNumber[disputeResolutionAgreementSignaturesCounter].signatoryRegistrationNumber,
            disputeResolutionAgreementSignaturesByNumber[disputeResolutionAgreementSignaturesCounter].signatoryAddress,
            disputeResolutionAgreementSignaturesByNumber[disputeResolutionAgreementSignaturesCounter].signedOnUnixTime
        );

    }

     

     
    uint public shareholdersCounter;

     
    uint public registeredShares;

     
    mapping(address => uint) public shareholderID;

     
    struct Shareholder {
        uint shareholderID;                                      
        address payable shareholderEthereumAddress;              
        string shareholderName;                                  
        string shareholderRegistrationNumber;                    
        string shareholderAddress;                               
        bool shareholderIsLegalPerson;                           
        string linkToSignersAuthorityToRepresentTheShareholder;  
        uint balanceOf;                                          
    }

    mapping(uint => Shareholder) public shareholdersLedgerByIdNumber;

    mapping(address => Shareholder) public shareholdersLedgerByEthAddress;

    event shareholderAddedOrUpdated(
        uint indexed shareholderID,
        address shareholderEthereumAddress,
        bool indexed isLegalPerson,
        string shareholderName,
        string shareholderRegistrationNumber,
        string shareholderAddress,
        uint shares,
        bool indexed newRegistration
    );

     
    function registerAsShareholderAndSignArbitrationAgreement(
        bool _isLegalPerson,
        string calldata _shareholderName,
        string calldata _shareholderRegistrationNumber,
        string calldata _shareholderAddress,
        string calldata _linkToSignersAuthorityToRepresentTheShareholder
    ) external returns (bool success){

        require(
            balanceOf[msg.sender] > 0,
            "To be registered address has to hold at least one token/share"
        );

        require(
            addressIsVerifiedByCryptonomica(msg.sender),
            "Shareholder address has to be verified on Cryptonomica"
        );

        bool newShareholder;
        uint id;

        if (shareholderID[msg.sender] == 0) {
            shareholdersCounter++;
            id = shareholdersCounter;
            shareholderID[msg.sender] = id;
            newShareholder = true;
             
            registeredShares = registeredShares.add(balanceOf[msg.sender]);
        } else {
            id = shareholderID[msg.sender];
            newShareholder = false;
        }

         
        shareholdersLedgerByIdNumber[id].shareholderID = id;
         
        shareholdersLedgerByIdNumber[id].shareholderEthereumAddress = msg.sender;
         
        shareholdersLedgerByIdNumber[id].shareholderName = _shareholderName;
         
        shareholdersLedgerByIdNumber[id].shareholderRegistrationNumber = _shareholderRegistrationNumber;
         
        shareholdersLedgerByIdNumber[id].shareholderAddress = _shareholderAddress;
         
        shareholdersLedgerByIdNumber[id].shareholderIsLegalPerson = _isLegalPerson;
         
        shareholdersLedgerByIdNumber[id].linkToSignersAuthorityToRepresentTheShareholder = _linkToSignersAuthorityToRepresentTheShareholder;
         
        shareholdersLedgerByIdNumber[id].balanceOf = balanceOf[msg.sender];

         
        shareholdersLedgerByEthAddress[msg.sender] = shareholdersLedgerByIdNumber[id];

        emit shareholderAddedOrUpdated(
            shareholdersLedgerByIdNumber[id].shareholderID,
            shareholdersLedgerByIdNumber[id].shareholderEthereumAddress,
            shareholdersLedgerByIdNumber[id].shareholderIsLegalPerson,
            shareholdersLedgerByIdNumber[id].shareholderName,
            shareholdersLedgerByIdNumber[id].shareholderRegistrationNumber,
            shareholdersLedgerByIdNumber[id].shareholderAddress,
            shareholdersLedgerByIdNumber[id].balanceOf,
            newShareholder
        );

         
        signDisputeResolutionAgreement(
            id,
            shareholdersLedgerByIdNumber[id].shareholderName,
            shareholdersLedgerByIdNumber[id].shareholderRegistrationNumber,
            shareholdersLedgerByIdNumber[id].shareholderAddress
        );

        return true;
    }

     

     
    uint public dividendsPeriod;

     
    struct DividendsRound {
        bool roundIsRunning;  
        uint sumWeiToPayForOneToken;  
        uint sumXEurToPayForOneToken;  
        uint allRegisteredShareholders;  
        uint shareholdersCounter;  
        uint registeredShares;  
        uint roundStartedOnUnixTime;  
        uint roundFinishedOnUnixTime;  
        uint weiForTxFees;  
    }

     
    uint public dividendsRoundsCounter;
    mapping(uint => DividendsRound) public dividendsRound;

     
    event DividendsPaymentsStarted(
        uint indexed dividendsRound,  
        address indexed startedBy,  
        uint totalWei,  
        uint totalXEur,  
        uint sharesToPayDividendsTo,  
        uint sumWeiToPayForOneShare,  
        uint sumXEurToPayForOneShare  
    );

     
    event DividendsPaymentsFinished(
        uint indexed dividendsRound
    );

     
    event DividendsPaymentEther (
        bool indexed success,
        address indexed to,
        uint shareholderID,
        uint shares,
        uint sumWei,
        uint indexed dividendsRound
    );

     
    event DividendsPaymentXEuro (
        bool indexed success,
        address indexed to,
        uint shareholderID,
        uint shares,
        uint sumXEuro,
        uint indexed dividendsRound
    );

     
    function startDividendsPayments() public returns (bool success) {

        require(
            dividendsRound[dividendsRoundsCounter].roundIsRunning == false,
            "Already running"
        );

         
         
        require(now.sub(dividendsRound[dividendsRoundsCounter].roundFinishedOnUnixTime) > dividendsPeriod,
            "To early to start"
        );

        require(registeredShares > 0,
            "No registered shares to distribute dividends to"
        );

        uint sumWeiToPayForOneToken = address(this).balance / registeredShares;
        uint sumXEurToPayForOneToken = xEuro.balanceOf(address(this)) / registeredShares;

        require(
            sumWeiToPayForOneToken > 0 || sumXEurToPayForOneToken > 0,
            "Nothing to pay"
        );

         
        dividendsRoundsCounter++;

        dividendsRound[dividendsRoundsCounter].roundIsRunning = true;
        dividendsRound[dividendsRoundsCounter].roundStartedOnUnixTime = now;
        dividendsRound[dividendsRoundsCounter].registeredShares = registeredShares;
        dividendsRound[dividendsRoundsCounter].allRegisteredShareholders = shareholdersCounter;

        dividendsRound[dividendsRoundsCounter].sumWeiToPayForOneToken = sumWeiToPayForOneToken;
        dividendsRound[dividendsRoundsCounter].sumXEurToPayForOneToken = sumXEurToPayForOneToken;

        emit DividendsPaymentsStarted(
            dividendsRoundsCounter,
            msg.sender,
            address(this).balance,
            xEuro.balanceOf(address(this)),
            registeredShares,
            sumWeiToPayForOneToken,
            sumXEurToPayForOneToken
        );

        return true;
    }

     
    event FeeForDividendsDistributionTxPaid(
        uint indexed dividendsRoundNumber,
        uint dividendsToShareholderNumber,
        address dividendsToShareholderAddress,
        address indexed feePaidTo,
        uint feeInWei,
        bool feePaymentSuccesful
    );

     
    function payDividendsToNext() external returns (bool success) {

        require(
            dividendsRound[dividendsRoundsCounter].roundIsRunning,
            "Dividends payments round is not open"
        );

        dividendsRound[dividendsRoundsCounter].shareholdersCounter = dividendsRound[dividendsRoundsCounter].shareholdersCounter + 1;

        uint nextShareholderToPayDividends = dividendsRound[dividendsRoundsCounter].shareholdersCounter;

        uint sumWeiToPayForOneToken = dividendsRound[dividendsRoundsCounter].sumWeiToPayForOneToken;
        uint sumXEurToPayForOneToken = dividendsRound[dividendsRoundsCounter].sumXEurToPayForOneToken;

        address payable to = shareholdersLedgerByIdNumber[nextShareholderToPayDividends].shareholderEthereumAddress;

        if (balanceOf[to] > 0) {

            if (sumWeiToPayForOneToken > 0) {

                uint sumWeiToPay = sumWeiToPayForOneToken * balanceOf[to];

                 
                 
                 
                 
                bool result = to.send(sumWeiToPay);
                emit DividendsPaymentEther(
                    result,
                    to,
                    nextShareholderToPayDividends,
                    balanceOf[to],
                    sumWeiToPay,
                    dividendsRoundsCounter
                );
            }

            if (sumXEurToPayForOneToken > 0) {
                uint sumXEuroToPay = sumXEurToPayForOneToken * balanceOf[to];
                 
                bool result = xEuro.transfer(to, sumXEuroToPay);
                emit DividendsPaymentXEuro(
                    result,
                    to,
                    nextShareholderToPayDividends,
                    sumXEuroToPay,
                    nextShareholderToPayDividends,
                    dividendsRoundsCounter
                );
                 
            }

        }

         
         

        uint feeForTxCaller = dividendsRound[dividendsRoundsCounter].weiForTxFees / shareholdersCounter;

        if (
            feeForTxCaller > 0
            && msg.sender == tx.origin  
        ) {

             
            bool feePaymentSuccessful = msg.sender.send(feeForTxCaller);
            emit FeeForDividendsDistributionTxPaid(
                dividendsRoundsCounter,
                nextShareholderToPayDividends,
                to,
                msg.sender,
                feeForTxCaller,
                feePaymentSuccessful
            );
        }

         
         
        if (nextShareholderToPayDividends == shareholdersCounter) {

            dividendsRound[dividendsRoundsCounter].roundIsRunning = false;
            dividendsRound[dividendsRoundsCounter].roundFinishedOnUnixTime = now;

            emit DividendsPaymentsFinished(
                dividendsRoundsCounter
            );
        }

        return true;
    }

     
    event FundsToPayForDividendsDistributionReceived(
        uint indexed forDividendsRound,
        uint sumInWei,
        address indexed from,
        uint currentSum
    );

     
    function fundDividendsPayout() public payable returns (bool success){

         
        require(
            dividendsRound[dividendsRoundsCounter].roundIsRunning,
            "Dividends payout is not running"
        );

        dividendsRound[dividendsRoundsCounter].weiForTxFees = dividendsRound[dividendsRoundsCounter].weiForTxFees + msg.value;

        emit FundsToPayForDividendsDistributionReceived(
            dividendsRoundsCounter,
            msg.value,
            msg.sender,
            dividendsRound[dividendsRoundsCounter].weiForTxFees  
        );

        return true;
    }

     
    function startDividendsPaymentsAndFundDividendsPayout() external payable returns (bool success) {
        startDividendsPayments();
        return fundDividendsPayout();
    }

     

     
    function approve(address _spender, uint _value) public returns (bool success){
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function approve(address _spender, uint _currentValue, uint _value) external returns (bool success){
        require(
            allowance[msg.sender][_spender] == _currentValue,
            "Current value in contract is different than provided current value"
        );
        return approve(_spender, _value);
    }

     
    function _transferFrom(address _from, address _to, uint _value) private returns (bool success) {

        require(
            _to != address(0),
            "_to was 0x0 address"
        );

        require(
            !dividendsRound[dividendsRoundsCounter].roundIsRunning,
            "Transfers blocked while dividends are distributed"
        );

        require(
            _from == msg.sender || _value <= allowance[_from][msg.sender],
            "Sender not authorized"
        );

         
        require(
            _value <= balanceOf[_from],
            "Account doesn't have required amount"
        );

        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);

        uint fromId = shareholderID[_from];
        uint toId = shareholderID[_to];

        if (fromId > 0) {
            shareholdersLedgerByEthAddress[_from].balanceOf = balanceOf[_from];
            shareholdersLedgerByIdNumber[fromId].balanceOf = balanceOf[_from];
        }

        if (toId > 0) {
            shareholdersLedgerByEthAddress[_to].balanceOf = balanceOf[_to];
            shareholdersLedgerByIdNumber[toId].balanceOf = balanceOf[_to];
        }

        if (fromId > 0 && toId == 0) {
             
             
            registeredShares = registeredShares.sub(_value);
        } else if (fromId == 0 && toId > 0) {
             
             
            registeredShares = registeredShares.add(_value);
        }

         
        if (_from != msg.sender) {
            allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        }

        emit Transfer(_from, _to, _value);

        return true;
    }

     
    function _erc223Call(address _to, uint _value, bytes memory _data) private returns (bool success) {

        uint codeLength;

        assembly {
         
            codeLength := extcodesize(_to)
        }

        if (codeLength > 0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
            emit DataSentToAnotherContract(msg.sender, _to, _data);
        }

        return true;
    }

     
    function transferFrom(address _from, address _to, uint _value) public returns (bool success){

        _transferFrom(_from, _to, _value);

         
         
         
        bytes memory empty = hex"00000000";

        return _erc223Call(_to, _value, empty);

    }  

     
    function transfer(address _to, uint _value) public returns (bool success){
        return transferFrom(msg.sender, _to, _value);
    }

     
    function transfer(address _to, uint _value, bytes calldata _data) external returns (bool success){

        _transferFrom(msg.sender, _to, _value);

        return _erc223Call(_to, _value, _data);
    }


     

     

     
    uint public votingCounterForContract;

     
    mapping(uint => string) public proposalText;

     
    mapping(uint => uint256) public numberOfVotersFor;
    mapping(uint => uint256) public numberOfVotersAgainst;

     
    mapping(uint => mapping(uint256 => address)) public votedFor;
    mapping(uint => mapping(uint256 => address)) public votedAgainst;

     
    mapping(uint => mapping(address => bool)) public boolVotedFor;
    mapping(uint => mapping(address => bool)) public boolVotedAgainst;

     
    mapping(uint => uint) public resultsInBlock;

     
    event Proposal(
        uint indexed proposalID,
        address indexed by,
        string proposalText,
        uint indexed resultsInBlock
    );

     
    modifier onlyShareholder() {
        require(
            shareholdersLedgerByEthAddress[msg.sender].shareholderID != 0 && balanceOf[msg.sender] > 0,
            "Only shareholder can do that"
        );
        _;
    }

     
    function createVoting(
        string calldata _proposalText,
        uint _resultsInBlock
    ) onlyShareholder external returns (bool success){

        require(
            _resultsInBlock > block.number,
            "Block for results should be later than current block"
        );

        votingCounterForContract++;

        proposalText[votingCounterForContract] = _proposalText;
        resultsInBlock[votingCounterForContract] = _resultsInBlock;

        emit Proposal(votingCounterForContract, msg.sender, proposalText[votingCounterForContract], resultsInBlock[votingCounterForContract]);

        return true;
    }

     
    event VoteFor(
        uint indexed proposalID,
        address indexed by
    );

     
    event VoteAgainst(
        uint indexed proposalID,
        address indexed by
    );

     
    function voteFor(uint256 _proposalId) onlyShareholder external returns (bool success){

        require(
            resultsInBlock[_proposalId] > block.number,
            "Voting already finished"
        );

        require(
            !boolVotedFor[_proposalId][msg.sender] && !boolVotedAgainst[_proposalId][msg.sender],
            "Already voted"
        );

        numberOfVotersFor[_proposalId] = numberOfVotersFor[_proposalId] + 1;

        uint voterId = numberOfVotersFor[_proposalId];

        votedFor[_proposalId][voterId] = msg.sender;

        boolVotedFor[_proposalId][msg.sender] = true;

        emit VoteFor(_proposalId, msg.sender);

        return true;
    }

     
    function voteAgainst(uint256 _proposalId) onlyShareholder external returns (bool success){

        require(
            resultsInBlock[_proposalId] > block.number,
            "Voting finished"
        );

        require(
            !boolVotedFor[_proposalId][msg.sender] && !boolVotedAgainst[_proposalId][msg.sender],
            "Already voted"
        );

        numberOfVotersAgainst[_proposalId] = numberOfVotersAgainst[_proposalId] + 1;

        uint voterId = numberOfVotersAgainst[_proposalId];

        votedAgainst[_proposalId][voterId] = msg.sender;

        boolVotedAgainst[_proposalId][msg.sender] = true;

        emit VoteAgainst(_proposalId, msg.sender);

        return true;
    }

     

    function addEtherToContract() external payable {
         
    }

    function() external payable {
         
    }

     
    function initToken(
        uint _contractNumberInTheLedger,
        string calldata _description,
        string calldata _name,
        string calldata _symbol,
        uint _dividendsPeriod,
        address _xEurContractAddress,
        address _cryptonomicaVerificationContractAddress,
        string calldata _disputeResolutionAgreement
    ) external returns (bool success) {

        require(
            msg.sender == creator,
            "Only creator can initialize token contract"
        );

        require(
            totalSupply == 0,
            "Contract already initialized"
        );

        contractNumberInTheLedger = _contractNumberInTheLedger;
        description = _description;
        name = _name;
        symbol = _symbol;
        xEuro = XEuro(_xEurContractAddress);
        cryptonomicaVerification = CryptonomicaVerification(_cryptonomicaVerificationContractAddress);
        disputeResolutionAgreement = _disputeResolutionAgreement;
        dividendsPeriod = _dividendsPeriod;

        return true;
    }

     
    function issueTokens(
        uint _totalSupply,
        address _tokenOwner
    ) external returns (bool success){

        require(
            msg.sender == creator,
            "Only creator can initialize token contract"
        );

        require(
            totalSupply == 0,
            "Contract already initialized"
        );

        require(
            _totalSupply > 0,
            "Number of tokens can not be zero"
        );


        totalSupply = _totalSupply;

        balanceOf[_tokenOwner] = totalSupply;

        emit Transfer(address(0), _tokenOwner, _totalSupply);

        return true;
    }

}

 

 
contract ManagedContract {

     
    CryptonomicaVerification public cryptonomicaVerification;

     
    mapping(address => bool) isAdmin;

    modifier onlyAdmin() {
        require(isAdmin[msg.sender], "Only admin can do that");
        _;
    }

     
    event CryptonomicaVerificationContractAddressChanged(address from, address to, address indexed by);

     
    function changeCryptonomicaVerificationContractAddress(address _newAddress) public onlyAdmin returns (bool success) {

        emit CryptonomicaVerificationContractAddressChanged(address(cryptonomicaVerification), _newAddress, msg.sender);

        cryptonomicaVerification = CryptonomicaVerification(_newAddress);

        return true;
    }

     
    event AdminAdded(
        address indexed added,
        address indexed addedBy
    );

     
    function addAdmin(address _newAdmin) public onlyAdmin returns (bool success){

        require(
            cryptonomicaVerification.keyCertificateValidUntil(_newAdmin) > now,
            "New admin has to be verified on Cryptonomica.net"
        );

         
        require(
            cryptonomicaVerification.revokedOn(_newAdmin) == 0,
            "Verification for this address was revoked, can not add"
        );

        isAdmin[_newAdmin] = true;

        emit AdminAdded(_newAdmin, msg.sender);

        return true;
    }

     
    event AdminRemoved(
        address indexed removed,
        address indexed removedBy
    );

     
    function removeAdmin(address _oldAdmin) external onlyAdmin returns (bool){

        require(msg.sender != _oldAdmin, "Admin can not remove himself");

        isAdmin[_oldAdmin] = false;

        emit AdminRemoved(_oldAdmin, msg.sender);

        return true;
    }

     

     
    address payable public withdrawalAddress;

     
    bool public withdrawalAddressFixed = false;

     
    event WithdrawalAddressChanged(
        address indexed from,
        address indexed to,
        address indexed changedBy
    );

     
    function setWithdrawalAddress(address payable _withdrawalAddress) public onlyAdmin returns (bool success) {

        require(
            !withdrawalAddressFixed,
            "Withdrawal address already fixed"
        );

        require(
            _withdrawalAddress != address(0),
            "Wrong address: 0x0"
        );

        require(
            _withdrawalAddress != address(this),
            "Wrong address: contract itself"
        );

        emit WithdrawalAddressChanged(withdrawalAddress, _withdrawalAddress, msg.sender);

        withdrawalAddress = _withdrawalAddress;

        return true;
    }

     
    event WithdrawalAddressFixed(
        address indexed withdrawalAddressFixedAs,
        address indexed fixedBy
    );

     
    function fixWithdrawalAddress(address _withdrawalAddress) external onlyAdmin returns (bool success) {

         
        require(
            !withdrawalAddressFixed,
            "Can't change, address fixed"
        );

         
        require(
            withdrawalAddress == _withdrawalAddress,
            "Wrong address in argument"
        );

        withdrawalAddressFixed = true;

        emit WithdrawalAddressFixed(withdrawalAddress, msg.sender);

        return true;
    }

     
    event Withdrawal(
        address indexed to,
        uint sumInWei,
        address indexed by,
        bool indexed success
    );

     
    function withdrawAllToWithdrawalAddress() external returns (bool success) {

         
         
         
         

        uint sum = address(this).balance;

        if (!withdrawalAddress.send(sum)) { 

            emit Withdrawal(withdrawalAddress, sum, msg.sender, false);

            return false;
        }

        emit Withdrawal(withdrawalAddress, sum, msg.sender, true);

        return true;
    }

}

 
contract ManagedContractWithPaidService is ManagedContract {

     
    uint public price;

     
    event PriceChanged(
        uint from,
        uint to,
        address indexed by
    );

     
    function changePrice(uint _newPrice) public onlyAdmin returns (bool success){
        emit PriceChanged(price, _newPrice, msg.sender);
        price = _newPrice;
        return true;
    }

}

 
contract CryptoSharesFactory is ManagedContractWithPaidService {

     
    string public disputeResolutionAgreement =
    "Any dispute, controversy or claim arising out of or relating to this smart contract, including transfer of shares/tokens managed by this smart contract or ownership of the shares/tokens, or any voting managed by this smart contract shall be settled by arbitration in accordance with the Cryptonomica Arbitration Rules (https://github.com/Cryptonomica/arbitration-rules) in the version in effect at the time of the filing of the claim. In the case of the Ethereum blockchain fork, the blockchain that has the highest hashrate is considered valid, and all the others are not considered a valid registry, in case of dispute, dispute should be resolved by arbitration court. All Ethereum test networks are not valid registries.";

    event DisputeResolutionAgreementTextChanged(
        string newText,
        address indexed changedBy
    );

     
    function changeDisputeResolutionAgreement(string calldata _newText) external onlyAdmin returns (bool success){

        disputeResolutionAgreement = _newText;

        emit DisputeResolutionAgreementTextChanged(_newText, msg.sender);

        return true;
    }

     
    event XEuroContractAddressChanged(
        address indexed from,
        address indexed to,
        address indexed by
    );

     
    function changeXEuroContractAddress(address _newAddress) public onlyAdmin returns (bool success) {

        emit XEuroContractAddressChanged(xEurContractAddress, _newAddress, msg.sender);

        xEurContractAddress = _newAddress;

        return true;
    }

     

    constructor() public {

        isAdmin[msg.sender] = true;

        changePrice(0.2 ether);

        setWithdrawalAddress(msg.sender);

         
        changeCryptonomicaVerificationContractAddress(0xE48BC3dB5b512d4A3e3Cd388bE541Be7202285B5);
         
         

         
        changeXEuroContractAddress(0x9a2A6C32352d85c9fcC5ff0f91fCB9CE42c15030);
         
         

    }  

     

     
    uint public cryptoSharesContractsCounter;

     
    struct CryptoSharesContract {
        uint contractId;
        address contractAddress;
        uint deployedOnUnixTime;
        string name;  
        string symbol;  
        uint totalSupply;  
        uint dividendsPeriod;  
    }

    event NewCryptoSharesContractCreated(
        uint indexed contractId,
        address indexed contractAddress,
        string name,  
        string symbol,  
        uint totalSupply,  
        uint dividendsPeriod  
    );

    mapping(uint => CryptoSharesContract) public cryptoSharesContractsLedger;

     
    function createCryptoSharesContract(
        string calldata _description,
        string calldata _name,
        string calldata _symbol,
        uint _totalSupply,
        uint _dividendsPeriodInSeconds
    ) external payable returns (bool success){

        require(
            msg.value >= price,
            "msg.value is less than price"
        );

        CryptoShares cryptoSharesContract = new CryptoShares();

        cryptoSharesContractsCounter++;

        cryptoSharesContract.initToken(
            cryptoSharesContractsCounter,
            _description,
            _name,
            _symbol,
            _dividendsPeriodInSeconds,
            xEurContractAddress,
            address(cryptonomicaVerification),
            disputeResolutionAgreement
        );

        cryptoSharesContract.issueTokens(
            _totalSupply,
            msg.sender
        );

        cryptoSharesContractsCounter;
        cryptoSharesContractsLedger[cryptoSharesContractsCounter].contractId = cryptoSharesContractsCounter;
        cryptoSharesContractsLedger[cryptoSharesContractsCounter].contractAddress = address(cryptoSharesContract);
        cryptoSharesContractsLedger[cryptoSharesContractsCounter].deployedOnUnixTime = now;
        cryptoSharesContractsLedger[cryptoSharesContractsCounter].name = cryptoSharesContract.name();
        cryptoSharesContractsLedger[cryptoSharesContractsCounter].symbol = cryptoSharesContract.symbol();
        cryptoSharesContractsLedger[cryptoSharesContractsCounter].totalSupply = cryptoSharesContract.totalSupply();
        cryptoSharesContractsLedger[cryptoSharesContractsCounter].dividendsPeriod = cryptoSharesContract.dividendsPeriod();

        emit NewCryptoSharesContractCreated(
            cryptoSharesContractsLedger[cryptoSharesContractsCounter].contractId,
            cryptoSharesContractsLedger[cryptoSharesContractsCounter].contractAddress,
            cryptoSharesContractsLedger[cryptoSharesContractsCounter].name,
            cryptoSharesContractsLedger[cryptoSharesContractsCounter].symbol,
            cryptoSharesContractsLedger[cryptoSharesContractsCounter].totalSupply,
            cryptoSharesContractsLedger[cryptoSharesContractsCounter].dividendsPeriod
        );

        return true;

    }  

}