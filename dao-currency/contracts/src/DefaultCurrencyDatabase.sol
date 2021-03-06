import "./CurrencyDatabase.sol";
import "../../../dao-core/contracts/src/Database.sol";

/// @title DefaultCurrencyDatabase
/// @author Andreas Olofsson (androlo1980@gmail.com)
/// @dev Default implementation of CurrencyDatabase.
contract DefaultCurrencyDatabase is CurrencyDatabase, DefaultDatabase {

    // No iterable mapping here. Iterate over users instead.
    mapping (address => uint) _balances;

    /// @notice DefaultCurrencyDatabase.add(receiver, amount) to add currency to an account.
    /// @dev Add currency to an account.
    /// @param receiver (address) the receiver account
    /// @param amount (int) the amount. Use a negative value to subtract.
    /// @return error (uint16) error code.
    function add(address receiver, int amount) returns (uint16 error) {
        if (!_checkCaller()) {
            return ACCESS_DENIED;
        }
        if (amount < 0) {
            if (_balances[receiver] < uint(-amount))
                return TRANSFER_FAILED;
            else
                _balances[receiver] -= uint(-amount);
        }
        else
            _balances[receiver] += uint(amount);
    }

    /// @notice DefaultCurrencyDatabase.send(sender, receiver, amount) to send currency from one account to another.
    /// @dev Send currency between accounts.
    /// @param sender (address) the sender account
    /// @param receiver (address) the receiver account
    /// @param amount (uint) the amount.
    /// @return error (uint16) error code.
    function send(address sender, address receiver, uint amount) returns (uint16 error) {
        if (!_checkCaller())
            return ACCESS_DENIED;
        if (_balances[sender] < amount)
            return INSUFFICIENT_SENDER_BALANCE;
        _balances[sender] -= amount;
        _balances[receiver] += amount;
    }

    /// @notice DefaultCurrencyDatabase.accountBalance(addr) get the balance of an account.
    /// @dev Get the balance of an account.
    /// @param addr (address) the account address
    /// @return balance (uint) the balance
    function accountBalance(address addr) constant returns (uint balance) {
        return _balances[addr];
    }

    /// @notice DefaultCurrencyDatabase.destroy() to destroy the contract.
    /// @dev Destroy a contract. Calls 'selfdestruct' if caller is Doug.
    /// @param fundReceiver (address) the account that receives the funds.
    function destroy(address fundReceiver) {
        if (msg.sender == address(_DOUG))
            selfdestruct(fundReceiver);
    }

}