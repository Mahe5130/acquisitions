import { jwtToken } from '#utils/jwt.js';
import logger from '#config/logger.js';

export const authenticateToken = (req, res, next) => {
  try {
    const token = req.cookies.token;

    if (!token) {
      return res.status(401).json({
        error: 'Unauthorized',
        message: 'Access token is required',
      });
    }

    const decoded = jwtToken.verify(token);
    req.user = decoded;
    next();
  } catch (e) {
    logger.error('Authentication failed:', e);
    return res.status(401).json({
      error: 'Unauthorized',
      message: 'Invalid or expired token',
    });
  }
};

export const requireRole = allowedRoles => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({
        error: 'Unauthorized',
        message: 'Authentication required',
      });
    }

    if (!allowedRoles.includes(req.user.role)) {
      logger.warn(
        `Access denied: User ${req.user.email} (${req.user.role}) tried to access resource requiring roles: ${allowedRoles.join(', ')}`
      );
      return res.status(403).json({
        error: 'Forbidden',
        message: 'Insufficient permissions',
      });
    }

    next();
  };
};
