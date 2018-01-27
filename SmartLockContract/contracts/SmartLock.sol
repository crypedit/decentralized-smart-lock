pragma solidity ^0.4.15;

import "./Decode.sol";

contract SmartLock {
	address landlord;
	bytes32 lockAddress;
	uint256 rentMoneyPerDay;
	address renter;
	uint256 totalRentMoneyFromRenter;
	uint256 lastDate;
	

	event RegisterLandlord(address landlord, bytes32 lockAddress, uint256 rentMoneyPerDay);
	event WantToRent(address renter, uint256 totalRentMoneyFromRenter, uint256 lastDate);
	event TransferRentMoney(address landlord, uint256 totalRentMoneyFromRenter);
	event ClearContract(address operator, uint256 now);

	modifier onlyLockIsAvailable { 
		require(isLockAvailiable());
		_; 
	}

	modifier notLandlord(address validateAddress) { 
		require(!isLandlord(validateAddress));
		_; 
	}

	modifier onlyLandlord(address landlord) { 
		require(isLandlord(landlord));
		_; 
	}

	modifier onlyRenter { 
		require(amIRentedThisRoom());
		_; 
	}

	function isLandlord(address landlordAddr) constant returns(bool res) {
		return landlord == landlordAddr;
	}
	
	function isLockAvailiable() constant returns(bool res) {
		return lastDate < now;
	}

	function amIRentedThisRoom() constant returns(bool res) {
		address addressNeedToVerify = msg.sender;
		return addressNeedToVerify == renter;
	}

	function getRentMoneyPerDay() constant returns(uint256 rentMoneyPerDay) {
		return rentMoneyPerDay;
	}

	function registerLandlord(bytes32 lockAddr, uint256 rentMoneyPD) {
		address landlordAddr = msg.sender;
		landlord = landlordAddr;
		lockAddress = lockAddr;
		rentMoneyPerDay = rentMoneyPD;
		renter = landlordAddr;
		totalRentMoneyFromRenter = 0;
		lastDate = 0;

		RegisterLandlord(landlordAddr, lockAddr, rentMoneyPD);
	}

	function() payable {
		wantToRent();
	}

	function wantToRent() onlyLockIsAvailable notLandlord(msg.sender) payable {
		address renterAddr = msg.sender;
		uint256 totalRentMoneyFromRenterSide = msg.value;

		renter = renterAddr;
		totalRentMoneyFromRenter = totalRentMoneyFromRenterSide;
		lastDate = now + (totalRentMoneyFromRenterSide / rentMoneyPerDay) * 1 days;

		WantToRent(renter, totalRentMoneyFromRenter, lastDate);
	}

	function canIOpenThisDoor(bytes memory sha3Message, bytes memory signedStr) constant returns(bool res) {
		return Decode.decode(sha3Message, signedStr) == renter && now < lastDate;
	}
	
	function transferRentMoney() onlyLandlord(msg.sender) onlyLockIsAvailable{
		address landlord = msg.sender;
		landlord.transfer(totalRentMoneyFromRenter);

		TransferRentMoney(landlord, totalRentMoneyFromRenter);

		clearContract();
	}
	
	function clearContract() private returns(bool res) {
		totalRentMoneyFromRenter = 0;
		renter = msg.sender;
		lastDate = 0;

		ClearContract(msg.sender, now);
	}
}
