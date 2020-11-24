 
    function balanceOf(address _tokenOwner) public view returns (uint256 balance)
    {
        return _balances[_tokenOwner].subtract(_totalReserved[_tokenOwner]);
    }

     
    function totalBalanceOf(address _tokenOwner) public view returns (uint256 balance)
    {
        return _balances[_tokenOwner];
    }

    function getReservation(address _tokenOwner, uint256 _nonce) public view returns (uint256 _amount, uint256 _fee, address _recipient, address _executor, uint256 _expiryBlockNum, ReservationStatus _status)
    {
        Reservation memory _reservation = _reserved[_tokenOwner][_nonce];

        _amount = _reservation._amount;
        _fee = _reservation._fee;
        _recipient = _reservation._recipient;
        _executor = _reservation._executor;
        _expiryBlockNum = _reservation._expiryBlockNum;

        if (_reservation._status == ReservationStatus.Active && _reservation._expiryBlockNum <= block.number)
        {
            _status = ReservationStatus.Expired;
        }
        else
        {
            _status = _reservation._status;
        }
    }

    function transfer(address _to, uint256 _value) public returns (bool success)
    {
        require(_balances[msg.sender].subtract(_totalReserved[msg.sender]) >= _value, "Insufficient balance for transfer");
        require(_to != address(0), "Can not transfer to zero address");

        _balances[msg.sender] = _balances[msg.sender].subtract(_value);
        _balances[_to] = _balances[_to].add(_value);

        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function transfer(address _from, address _to, uint256 _value, uint256 _fee, uint256 _nonce, bytes memory _sig) public returns (bool success)
    {
        require(_to != address(0), "Can not transfer to zero address");

        uint256 _valuePlusFee = _value.add(_fee);
        require(_balances[_from].subtract(_totalReserved[_from]) >= _valuePlusFee, "Insufficient balance for transfer");
        

        bytes32 hash = keccak256(abi.encodePacked(address(this), _from, _to, _value, _fee, _nonce));
        validateSignature(hash, _from, _nonce, _sig);

        _balances[_from] = _balances[_from].subtract(_valuePlusFee);
        _balances[_to] = _balances[_to].add(_value);
        _totalSupply = _totalSupply.subtract(_fee);

        emit Transfer(_from, _to, _value);
        emit Transfer(_from, address(0), _fee);
        emit Burnt(_from, _fee);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success)
    {
        require(_balances[_from].subtract(_totalReserved[_from]) >= _value, "Insufficient balance for transfer");
        require(_allowed[_from][msg.sender] >= _value, "Allowance exceeded");
        require(_to != address(0), "Can not transfer to zero address");

        _balances[_from] = _balances[_from].subtract(_value);
        _allowed[_from][msg.sender] = _allowed[_from][msg.sender].subtract(_value);
        _balances[_to] = _balances[_to].add(_value);

        emit Transfer(_from, _to, _value);

        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success)
    {
        require(_spender != address(0), "Invalid spender address");

        _allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        
        return true;
    }

    function allowance(address _tokenOwner, address _spender) public view returns (uint256 remaining)
    {
        return _allowed[_tokenOwner][_spender];
    }

    function burn(uint256 _value) public onlyOwner returns (bool success)
    {
        require(_balances[msg.sender].subtract(_totalReserved[msg.sender]) >= _value, "Insufficient balance for burn");

        _balances[msg.sender] = _balances[msg.sender].subtract(_value);
        _totalSupply = _totalSupply.subtract(_value);

        emit Transfer(msg.sender, address(0), _value);
        emit Burnt(msg.sender, _value);

        return true;
    }

    function mint(address _to, uint256 _value) public onlyOwner returns (bool success)
    {
        require(_to != address(0), "Can not mint to zero address");

        _balances[_to] = _balances[_to].add(_value);
        _totalSupply = _totalSupply.add(_value);

        emit Transfer(address(0), _owner, _value);
        emit Transfer(_owner, _to, _value);
        emit Mint(_to, _value);

        return true;
    }

    function reserve(address _from, address _to, address _executor, uint256 _amount, uint256 _fee, uint256 _nonce, uint256 _expiryBlockNum, bytes memory _sig) public returns (bool success)
    {
        require(_expiryBlockNum > block.number, "Invalid block expiry number");
        require(_amount > 0, "Invalid reserve amount");
        require(_from != address(0), "Can't reserve from zero address");
        require(_to != address(0), "Can't reserve to zero address");
        require(_executor != address(0), "Can't execute from zero address");

        uint256 _amountPlusFee = _amount.add(_fee);
        require(_balances[_from].subtract(_totalReserved[_from]) >= _amountPlusFee, "Insufficient funds to create reservation");

        bytes32 hash = keccak256(abi.encodePacked(address(this), _from, _to, _executor, _amount, _fee, _nonce, _expiryBlockNum));
        validateSignature(hash, _from, _nonce, _sig);

        _reserved[_from][_nonce] = Reservation(_amount, _fee, _to, _executor, _expiryBlockNum, ReservationStatus.Active);
        _totalReserved[_from] = _totalReserved[_from].add(_amountPlusFee);

        return true;
    }

    function execute(address _sender, uint256 _nonce) public returns (bool success)
    {
        Reservation storage _reservation = _reserved[_sender][_nonce];

        require(_reservation._status == ReservationStatus.Active, "Invalid reservation to execute");
        require(_reservation._expiryBlockNum > block.number, "Reservation has expired and can not be executed");
        require(_reservation._executor == msg.sender, "This address is not authorized to execute this reservation");

        uint256 _amountPlusFee = _reservation._amount.add(_reservation._fee);

        _balances[_sender] = _balances[_sender].subtract(_amountPlusFee);
        _balances[_reservation._recipient] = _balances[_reservation._recipient].add(_reservation._amount);
        _totalSupply = _totalSupply.subtract(_reservation._fee);

        emit Transfer(_sender, _reservation._recipient, _reservation._amount);
        emit Transfer(_sender, address(0), _reservation._fee);
        emit Burnt(_sender, _reservation._fee);

        _reserved[_sender][_nonce]._status = ReservationStatus.Completed;
        _totalReserved[_sender] = _totalReserved[_sender].subtract(_amountPlusFee);

        return true;
    }

    function reclaim(address _sender, uint256 _nonce) public returns (bool success)
    {
        Reservation storage _reservation = _reserved[_sender][_nonce];
        require(_reservation._status == ReservationStatus.Active, "Invalid reservation status");

        if (msg.sender != _owner)
        {
            require(msg.sender == _sender, "Can not reclaim another user's reservation for them");
            require(_reservation._expiryBlockNum <= block.number, "Reservation has not expired yet");
        }

        _reserved[_sender][_nonce]._status = ReservationStatus.Reclaimed;
        _totalReserved[_sender] = _totalReserved[_sender].subtract(_reservation._amount).subtract(_reservation._fee);

        return true;
    }

    function validateSignature(bytes32 _hash, address _from, uint256 _nonce, bytes memory _sig) internal
    {
        bytes32 messageHash = _hash.toEthSignedMessageHash();

        address _signer = messageHash.recover(_sig);
        require(_signer == _from, "Invalid signature");

        require(!_usedNonces[_signer][_nonce], "Nonce has already been used for this address");
        _usedNonces[_signer][_nonce] = true;

        emit NonceUsed(_signer, _nonce);
    }
}