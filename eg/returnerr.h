/*
 * Do an operating system operation
 * This is an example of a function which performs some sort of operating
 * system operation, returning an errno-like indication of its success or
 * failure.  We'd like the documentation to list all the possible failure
 * indications that this function can return, which is only a tiny subset of
 * all the possible errno values.  Hence, we don't define it as returning an
 * enum of some sort, since that would cause c2man to list every possible value
 * that type can have.
 * Returns an indication of success or failure, as follows:
 *	EOK: Success
 *	EIO: I/O error
 *	ENOMEM: Out of memory
 *	EIEIO: Old Macdonald error
 */
int reterrno();
