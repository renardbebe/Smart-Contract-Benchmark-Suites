 

pragma solidity ^0.5.6;

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract IOperationalWallet2 {
    function setTrustedToggler(address _trustedToggler) external;
    function toggleTrustedWithdrawer(address _withdrawer, bool isEnabled) external;
    function withdrawCoin(address coin, address to, uint256 amount) external returns (bool);
}

interface IWithdrawalOracle {
    function get(address coinAddress) external view returns (bool, uint, uint);
    function set(address coinAddress, bool _isEnabled, uint _currencyAmount, uint _zangllTokenAmount) external;
}

contract IBooking {

    enum Status {
        New, Requested, Confirmed, Rejected, Canceled, Booked, Started,
        Finished, Arbitration, ArbitrationFinished, ArbitrationPossible
    }
    enum CancellationPolicy {Soft, Flexible, Strict}


     
    function calculateCancel() external view returns(bool, uint, uint, uint);
    function cancel() external;

    function setArbiter(address _arbiter) external;
    function submitToArbitration(int _ticket) external;

    function arbitrate(uint depositToHostPpm, uint cleaningToHostPpm, uint priceToHostPpm, bool useCancellationPolicy) external;

    function calculateHostWithdraw() external view returns (bool isPossible, uint zangllTokenAmountToPut, uint hostPart);
    function hostWithdraw() external;

    function calculateGuestWithdraw() external view returns (bool isPossible, uint guestPart);
    function guestWithdraw() external;

     
    function bookingId() external view returns(uint128);
    function dateFrom() external view returns(uint32);
    function dateTo() external view returns(uint32);
    function dateCancel() external view returns(uint32);
    function host() external view returns(address);
    function guest() external view returns(address);
    function cancellationPolicy() external view returns (IBooking.CancellationPolicy);

    function guestCoin() external view returns(address);
    function hostCoin() external view returns(address);
    function withdrawalOracle() external view returns(address);

    function price() external view returns(uint256);
    function cleaning() external view returns(uint256);
    function deposit() external view returns(uint256);

    function guestAmount() external view returns (uint256);

    function feeBeneficiary() external view returns(address);

    function ticket() external view returns(int);

    function arbiter() external view returns(address);

    function balance() external view returns (uint);
    function balanceToken(address) external view returns (uint);
    function status() external view returns(Status);
}

contract IBookingFactory {

    function createBooking(uint128 _bookingId, uint32 _dateFrom, uint32 _dateTo, uint256 _guestAmount,
        uint256 _price, uint256 _cleaning, uint256 _deposit, IBooking.CancellationPolicy _cancellationPolicy,
        address _guest, address _host, address _guestCoin, address _hostCoin)
    public payable returns (address);

    function toggleCoin(address coinAddress, bool enable) public;

    function setFeeBeneficiary(address _feeBeneficiary) public;
    function setOperationalWallet1(address payable _operationalWallet1) public;
    function setOperationalWallet2(address _operationalWallet2) public;

    function addArbiter(address _arbiter) public;
    function removeArbiter(address _arbiter) public;
    function setBookingArbiter(address _arbiter, address _booking) public;
}

library BookingLib {

    struct Booking {
        uint128 bookingId;
        uint32 dateFrom;
        uint32 dateTo;
        uint32 dateCancel;

        address withdrawalOracle;
        address operationalWallet2;

        address guestCoin;
        address hostCoin;
        address znglToken;

         
        uint256 price;
        uint256 cleaning;
        uint256 deposit;

         
        uint256 guestAmount;

        address host;
        address guest;
        address feeBeneficiary;
        IBooking.Status status;
        IBooking.CancellationPolicy cancellationPolicy;
        address factory;
        address arbiter;
        int ticket;

        bool guestFundsWithdriven;  
        bool hostFundsWithdriven;   

        uint256 guestWithdrawAllowance;  
        uint256 hostWithdrawAllowance;   
    }

     
    event StatusChanged (
        IBooking.Status indexed _from,
        IBooking.Status indexed _to
    );

    function getStatus(Booking storage booking)
    internal view returns (IBooking.Status) {
        if (booking.dateCancel == 0) {
             
            if (booking.status == IBooking.Status.Booked) {
                if (now < booking.dateFrom) {
                    return IBooking.Status.Booked;
                } else if (now < booking.dateTo) {
                    return IBooking.Status.Started;
                } else if (now < booking.dateTo + 24 * 60 * 60) {
                    return IBooking.Status.ArbitrationPossible;
                } else {
                    return IBooking.Status.Finished;
                }
            } else {
                return booking.status;
            }
        } else {
             
            if (booking.status == IBooking.Status.ArbitrationFinished) {
                return booking.status;
            }
            if (now < booking.dateCancel + 24 * 60 * 60) {
                return IBooking.Status.ArbitrationPossible;
            } else {
                return IBooking.Status.Canceled;
            }
        }
    }

    function setStatus(Booking storage booking, IBooking.Status newStatus)
    internal {
        emit StatusChanged(booking.status, newStatus);
        booking.status = newStatus;
    }
     

     
    function isStatusAllowsWithdrawal(Booking storage booking)
    internal view returns (bool) {
        IBooking.Status currentStatus = getStatus(booking);
        return (
            currentStatus == IBooking.Status.Finished ||
            currentStatus == IBooking.Status.ArbitrationFinished ||
            currentStatus == IBooking.Status.Canceled
        );
    }

    function calculateGuestWithdraw(Booking storage booking)
    internal view returns (bool, uint) {
        if (!booking.guestFundsWithdriven &&
            isStatusAllowsWithdrawal(booking) &&
            IERC20(booking.hostCoin).balanceOf(booking.operationalWallet2) >= booking.guestWithdrawAllowance
        ) {
            return (true, booking.guestWithdrawAllowance);
        } else {
            return (false, 0);
        }
    }

    function guestWithdraw(Booking storage booking) internal {
        (bool isPossible, uint guestPart) = calculateGuestWithdraw(booking);
        require(isPossible);

        bool isWithdrawSuccessful = IOperationalWallet2(booking.operationalWallet2)
            .withdrawCoin(booking.hostCoin, booking.guest, guestPart);
        require(isWithdrawSuccessful);
        booking.guestFundsWithdriven = true;
    }

    function calculateHostWithdraw(Booking storage booking) internal view
    returns (bool isPossible, uint zangllTokenAmountToPut, uint hostPart) {
        (bool isCoinEnabled, uint currencyAmount, uint zangllTokenAmount) =
            IWithdrawalOracle(booking.withdrawalOracle).get(booking.hostCoin);

        if (!booking.hostFundsWithdriven &&
            isStatusAllowsWithdrawal(booking) &&
            isCoinEnabled &&
            IERC20(booking.hostCoin).balanceOf(booking.operationalWallet2) >= booking.hostWithdrawAllowance
        ) {
            isPossible = true;
            zangllTokenAmountToPut = booking.hostWithdrawAllowance * zangllTokenAmount / currencyAmount;
            hostPart = booking.hostWithdrawAllowance;
        } else {
            isPossible = false;
            zangllTokenAmountToPut = 0;
            hostPart = 0;
        }
    }

    function hostWithdraw(Booking storage booking) internal {
        (bool isPossible, uint zangllTokenAmountToPut, uint hostPart) = calculateHostWithdraw(booking);
        require(isPossible);

        bool isZnglTokenWithdrawSuccessful = IERC20(booking.znglToken)
            .transferFrom(booking.host, booking.feeBeneficiary, zangllTokenAmountToPut);
        require(isZnglTokenWithdrawSuccessful);

        bool isWithdrawSuccessful = IOperationalWallet2(booking.operationalWallet2)
            .withdrawCoin(booking.hostCoin, booking.host, hostPart);
        require(isWithdrawSuccessful);
        booking.hostFundsWithdriven = true;
    }
     

     
    function calculateCancel(Booking storage booking)
    internal view returns (bool isPossible, uint depositToHostPpm, uint cleaningToHostPpm, uint priceToHostPpm) {

         
        isPossible = false;
        IBooking.Status currentStatus = getStatus(booking);

        (uint nightsAlreadyOccupied, uint nightsTotal) = getNights(booking);

         
        if ((currentStatus != IBooking.Status.Booked && currentStatus != IBooking.Status.Started) ||
            (nightsTotal == 0 || nightsAlreadyOccupied >= nightsTotal) ||
            (currentStatus == IBooking.Status.Started && msg.sender == booking.host)) {
            return (false, 0, 0, 0);
        }

        depositToHostPpm = 0;
        cleaningToHostPpm = nightsAlreadyOccupied == 0 ? 0 : 1000000;
        priceToHostPpm = currentStatus == IBooking.Status.Booked && (msg.sender == booking.host || msg.sender == booking.feeBeneficiary)
            ? 0
            : getPriceToHostPpmByCancellationPolicy(booking, nightsAlreadyOccupied, nightsTotal, now);

        isPossible = true;
    }

    function cancel(Booking storage booking)
    internal {
        bool isPossible; uint depositToHostPpm; uint cleaningToHostPpm; uint priceToHostPpm;
        (isPossible, depositToHostPpm, cleaningToHostPpm, priceToHostPpm) = calculateCancel(booking);
        require(isPossible);

        booking.dateCancel = uint32(now);
        splitAllBalance(booking, depositToHostPpm, cleaningToHostPpm, priceToHostPpm);
        emit StatusChanged(booking.status, IBooking.Status.ArbitrationPossible);
    }
     

     
    function setArbiter(Booking storage booking, address _arbiter)
    internal {
        require(msg.sender == booking.factory);
        booking.arbiter = _arbiter;
    }

    function submitToArbitration(Booking storage booking, int _ticket)
    internal {
        IBooking.Status currentStatus = getStatus(booking);
        require(
            currentStatus == IBooking.Status.Booked ||
            currentStatus == IBooking.Status.Started ||
            currentStatus == IBooking.Status.ArbitrationPossible
        );
        require(!booking.guestFundsWithdriven && !booking.hostFundsWithdriven);
        booking.ticket = _ticket;
        setStatus(booking, IBooking.Status.Arbitration);
    }

    function arbitrate(Booking storage booking,
        uint depositToHostPpm, uint cleaningToHostPpm, uint priceToHostPpm, bool useCancellationPolicy)
    internal {
        require (booking.status == IBooking.Status.Arbitration && depositToHostPpm <= 1000000 &&
            cleaningToHostPpm <= 1000000 && priceToHostPpm <= 1000000);

        if (useCancellationPolicy) {
            (uint nightsAlreadyOccupied, uint nightsTotal) = getNights(booking);
            priceToHostPpm = getPriceToHostPpmByCancellationPolicy(booking, nightsAlreadyOccupied, nightsTotal, now);
        }

        splitAllBalance(booking, depositToHostPpm, cleaningToHostPpm, priceToHostPpm);
        setStatus(booking, IBooking.Status.ArbitrationFinished);
    }
     

     
    function splitAllBalance(Booking storage booking,
        uint depositToHostPpm, uint cleaningToHostPpm, uint priceToHostPpm)
    internal {
        uint priceToHost = booking.price * priceToHostPpm / 1000000;
        uint depositToHost = booking.deposit * depositToHostPpm / 1000000;
        uint cleaningToHost = booking.cleaning * cleaningToHostPpm / 1000000;

        booking.hostWithdrawAllowance = priceToHost + cleaningToHost + depositToHost;
        booking.guestWithdrawAllowance =
            (booking.price - priceToHost) +
            (booking.deposit - depositToHost) +
            (booking.cleaning - cleaningToHost);
    }

     
    function getNights(Booking storage booking)
    internal view returns (uint nightsAlreadyOccupied, uint nightsTotal) {
        nightsTotal = (12 * 60 * 60 + booking.dateTo - booking.dateFrom) / (24 * 60 * 60);
        if (now <= booking.dateFrom) {
            nightsAlreadyOccupied = 0;
        } else {
             
            nightsAlreadyOccupied = (24 * 60 * 60 - 1 + now - booking.dateFrom) / (24 * 60 * 60);
        }
        if (nightsAlreadyOccupied > nightsTotal) {
            nightsAlreadyOccupied = nightsTotal;
        }
    }

    function getPriceToHostPpmByCancellationPolicy(
        Booking storage booking, uint nightsAlreadyOccupied, uint nightsTotal, uint _now)
    internal view returns (uint priceToHostPpm) {
        if (booking.cancellationPolicy == IBooking.CancellationPolicy.Flexible) {
            uint nightsToPay = _now < booking.dateFrom - 24 * 60 * 60
                ? 0
                : nightsAlreadyOccupied >= nightsTotal ? nightsTotal : nightsAlreadyOccupied + 1;
            priceToHostPpm = 1000000 * nightsToPay / nightsTotal;
        } else if (booking.cancellationPolicy == IBooking.CancellationPolicy.Strict) {
            priceToHostPpm = _now < booking.dateFrom - 5 * 24 * 60 * 60
                ? 0
                : (nightsTotal - (nightsTotal - nightsAlreadyOccupied) / 2) * 1000000;
        } else { 
            priceToHostPpm = 1000000 * nightsAlreadyOccupied / nightsTotal;
        }
    }
     
}

contract Booking is IBooking {

    using BookingLib for BookingLib.Booking;

    BookingLib.Booking booking;

    event StatusChanged (
        IBooking.Status indexed from,
        IBooking.Status indexed to
    );

    modifier onlyFactory {
        require(msg.sender == booking.factory);
        _;
    }

    modifier onlyGuest {
        require(msg.sender == booking.guest);
        _;
    }

    modifier onlyHost {
        require(msg.sender == booking.host);
        _;
    }

    modifier onlyFeeBeneficiary {
        require(msg.sender == booking.feeBeneficiary);
        _;
    }

    modifier onlyParticipant {
        require(msg.sender == booking.guest || msg.sender == booking.host || msg.sender == booking.feeBeneficiary);
        _;
    }

    modifier onlyArbiter {
        require(msg.sender == booking.arbiter);
        _;
    }

    constructor(address _znglToken, uint128 _bookingId, uint32 _dateFrom, uint32 _dateTo, uint256 _guestAmount,
        uint256 _price, uint256 _cleaning, uint256 _deposit, IBooking.CancellationPolicy _cancellationPolicy,
        address _guest, address _host, address _feeBeneficiary, address _defaultArbiter
    ) public {
        require(_dateFrom < _dateTo);
        require(_host != _guest);

        booking.znglToken = _znglToken;
        booking.bookingId = _bookingId;
        booking.dateFrom = _dateFrom;
        booking.dateTo = _dateTo;

        booking.guestAmount = _guestAmount;
        booking.price = _price;
        booking.cleaning = _cleaning;
        booking.deposit = _deposit;

        booking.cancellationPolicy = _cancellationPolicy;
        booking.host = _host;
        booking.guest = _guest;
        booking.feeBeneficiary = _feeBeneficiary;
        booking.arbiter = _defaultArbiter;

        booking.factory = msg.sender;

        booking.status = IBooking.Status.Booked;

        booking.guestFundsWithdriven = false;
        booking.hostFundsWithdriven = false;

        booking.guestWithdrawAllowance = _deposit;
        booking.hostWithdrawAllowance = _price + _cleaning;
    }

    function setAdditionalInfo(address _operationalWallet2, address _withdrawalOracle,
        address _guestCoin, address _hostCoin)
    external onlyFactory {
        booking.operationalWallet2 = _operationalWallet2;
        booking.withdrawalOracle = _withdrawalOracle;
        booking.guestCoin = _guestCoin;
        booking.hostCoin = _hostCoin;
    }

    function calculateCancel() external view onlyParticipant returns(bool, uint, uint, uint) {
        return booking.calculateCancel();
    }

    function cancel() external onlyParticipant {
        booking.cancel();
    }

    function setArbiter(address _arbiter) external {
        booking.setArbiter(_arbiter);
    }

    function submitToArbitration(int _ticket) external onlyParticipant {
        booking.submitToArbitration(_ticket);
    }

    function arbitrate(uint depositToHostPpm, uint cleaningToHostPpm, uint priceToHostPpm, bool useCancellationPolicy)
    external onlyArbiter {
        booking.arbitrate(depositToHostPpm, cleaningToHostPpm, priceToHostPpm, useCancellationPolicy);
    }

    function bookingId() external view returns (uint128) {
        return booking.bookingId;
    }

    function dateFrom() external view returns (uint32) {
        return booking.dateFrom;
    }

    function dateTo() external view returns (uint32) {
        return booking.dateTo;
    }

    function dateCancel() external view returns (uint32) {
        return booking.dateCancel;
    }

    function host() external view returns (address) {
        return booking.host;
    }

    function guest() external view returns (address) {
        return booking.guest;
    }

    function cancellationPolicy() external view returns (IBooking.CancellationPolicy) {
        return booking.cancellationPolicy;
    }

    function guestCoin() external view returns (address) {
        return booking.guestCoin;
    }

    function hostCoin() external view returns (address) {
        return booking.hostCoin;
    }

    function withdrawalOracle() external view returns (address) {
        return booking.withdrawalOracle;
    }

    function price() external view returns (uint256) {
        return booking.price;
    }

    function cleaning() external view returns (uint256) {
        return booking.cleaning;
    }

    function deposit() external view returns (uint256) {
        return booking.deposit;
    }

    function guestAmount() external view returns (uint256) {
        return booking.guestAmount;
    }

    function feeBeneficiary() external view returns (address) {
        return booking.feeBeneficiary;
    }

    function ticket() external view returns(int) {
        return booking.ticket;
    }

    function arbiter() external view returns(address) {
        return booking.arbiter;
    }

    function balance() external view returns (uint) {
        return address(this).balance;
    }

    function balanceToken(address _token) external view returns (uint) {
        return IERC20(_token).balanceOf(address(this));
    }

    function status() external view returns (IBooking.Status) {
        return booking.getStatus();
    }

    function calculateHostWithdraw() onlyHost external view
    returns (bool isPossible, uint zangllTokenAmountToPut, uint hostPart) {
        return booking.calculateHostWithdraw();
    }

    function hostWithdraw() external {
        require(msg.sender == booking.host || msg.sender == booking.znglToken);
        booking.hostWithdraw();
    }

    function calculateGuestWithdraw() onlyGuest external view
    returns (bool isPossible, uint guestPart) {
        return booking.calculateGuestWithdraw();
    }

    function guestWithdraw() external onlyGuest {
        booking.guestWithdraw();
    }
}

contract BookingFactory is Ownable, IBookingFactory {

    event BookingCreated (
        address indexed bookingContractAddress,
        uint128 indexed bookingId
    );

     
    mapping(address => bool) public enabledCoins;
    function toggleCoin(address coinAddress, bool enable) public onlyOwner {
        enabledCoins[coinAddress] = enable;
    }
     

    address public znglToken;
    address payable public operationalWallet1;  
    address public operationalWallet2;  
    address public withdrawalOracle;

    mapping(uint128 => bool) private bookingIds;
    mapping(address => bool) private arbiters;
    address public feeBeneficiary;

    constructor(address _znglToken, address _withdrawalOracle, address payable _operationalWallet1, address _operationalWallet2)
    public {
        feeBeneficiary = owner();
        znglToken = _znglToken;
        withdrawalOracle = _withdrawalOracle;
        operationalWallet1 = _operationalWallet1;
        operationalWallet2 = _operationalWallet2;
    }

    function createBooking(uint128 _bookingId, uint32 _dateFrom, uint32 _dateTo, uint256 _guestAmount,
        uint256 _price, uint256 _cleaning, uint256 _deposit, IBooking.CancellationPolicy _cancellationPolicy,
        address _guest, address _host, address _guestCoin, address _hostCoin)
    public payable returns (address) {
        require(msg.value > 0 || enabledCoins[_guestCoin]);
        require(enabledCoins[_hostCoin]);
        require(!bookingIds[_bookingId]);
        bookingIds[_bookingId] = true;

        Booking booking = new Booking(znglToken, _bookingId, _dateFrom, _dateTo, _guestAmount,
            _price, _cleaning, _deposit, _cancellationPolicy,
            _guest, _host, feeBeneficiary, owner());
        emit BookingCreated(address(booking), _bookingId);

        if (msg.value > 0) {
            booking.setAdditionalInfo(operationalWallet2, withdrawalOracle, 0x0000000000000000000000000000000000000000, _hostCoin);
            operationalWallet1.transfer(_guestAmount);
            if (address(this).balance > 0) {
                msg.sender.transfer(address(this).balance);
            }
        } else {
            booking.setAdditionalInfo(operationalWallet2, withdrawalOracle, _guestCoin, _hostCoin);
            IERC20(_guestCoin).transferFrom(_guest, operationalWallet1, _guestAmount);
        }

        IOperationalWallet2(operationalWallet2).toggleTrustedWithdrawer(address(booking), true);

        return address(booking);
    }

    function setFeeBeneficiary(address _feeBeneficiary) public onlyOwner {
        feeBeneficiary = _feeBeneficiary;
    }

    function setOperationalWallet1(address payable _operationalWallet1) public onlyOwner {
        operationalWallet1 = _operationalWallet1;
    }

    function setOperationalWallet2(address _operationalWallet2) public onlyOwner {
        operationalWallet2 = _operationalWallet2;
    }

    function addArbiter(address _arbiter) public {
        require (isOwner() || arbiters[msg.sender]);
        arbiters[_arbiter] = true;
    }

    function removeArbiter(address _arbiter) public {
        require (isOwner() || arbiters[msg.sender]);
        arbiters[_arbiter] = false;
    }

    function setBookingArbiter(address _arbiter, address _booking) public onlyOwner {
        require(arbiters[_arbiter], "Arbiter should be added to arbiter list first");
        Booking booking = Booking(_booking);
        booking.setArbiter(_arbiter);
    }
}